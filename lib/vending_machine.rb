require 'money'

class VendingMachine
  def initialize(items, balance)
    @items = items
    @balance = balance
  end

  def select_item(item_name, payment)
    item = items.find { |item| item.name == item_name }

    process_payment(item, payment)
  end

  attr_reader :items
  attr_accessor :balance

  private

  def process_payment(item, payment)
    return 'Item not available' unless item_available?(item)

    # Validate payment denominations
    unless payment_denominations_valid?(payment)
      return "Invalid coin denomination in payment: #{payment.keys - Change::ACCEPTABLE_COINS}"
    end

    total_payment_for_item = payment.sum { |denom, count| denom * count }

    unless total_payment_for_item >= item.price
      return specify_amount_pending(item, total_payment_for_item - item.price)
    end

    change = process_change(item, payment, total_payment_for_item)
    if change >= 0
      # Decrement item quantity after successful purchase
      item.quantity -= 1
      confirm_payment(item, change)
    else
      specify_amount_pending(item, change)
    end
  end

  def payment_denominations_valid?(payment)
    payment.keys.all? { |denom| Change::ACCEPTABLE_COINS.include?(denom) }
  end

  def calculate_total_balance
    @balance.calculate_total_amount
  end

  def confirm_payment(item, change)
    if change > 0
      "Thank you for your purchase of #{item.name}. Please collect your item and change: #{change}"
    else
      "Thank you for your purchase of #{item.name}. Please collect your item."
    end
  end

  def specify_amount_pending(item, change)
    "You need to pay #{change.abs} more cents to purchase #{item.name}"
  end

  def item_available?(item)
    if item && item.quantity > 0
      true
    else
      false
    end
  end

  def process_change(item, payment, total_payment_for_item)
    change_in_cents = total_payment_for_item > item.price ? total_payment_for_item - item.price : 0

    update_machine_balance(payment, change_in_cents)
    change_in_cents
  end

  def update_machine_balance(payment, change_in_cents)
    # Add the payment coins to the machine's balance
    new_balance = @balance.amount.dup
    payment.each do |denom, count|
      new_balance[denom] ||= 0
      new_balance[denom] += count
    end

    # Subtract the change given to the user from the updated balance
    new_balance = subtract_change_from_balance(new_balance, change_in_cents) if change_in_cents && change_in_cents > 0

    @balance = Change.new(new_balance)
  end

  def subtract_change_from_balance(balance, change_amount)
    # Calculate change using available denominations
    remaining_change = change_amount
    new_balance = balance.dup

    # Sort denominations in descending order to give larger coins first
    Change::ACCEPTABLE_COINS.sort.reverse.each do |denomination|
      next if remaining_change <= 0

      available_coins = new_balance[denomination] || 0
      coins_to_give = [available_coins, remaining_change / denomination].min

      if coins_to_give > 0
        new_balance[denomination] = available_coins - coins_to_give
        remaining_change -= coins_to_give * denomination
      end
    end

    # Remove denominations with zero quantity
    new_balance.reject! { |_, quantity| quantity <= 0 }

    new_balance
  end
end
