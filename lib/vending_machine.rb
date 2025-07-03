require 'money'

class VendingMachine
  def initialize(items, balance)
    @items = items
    @balance = balance
  end

  def select_item(item_name, amount)
    item = items.find { |item| item.name == item_name }
    if check_item_availability(item) && balance.amount >= item.price
      change = process_payment(item.price, amount)
      change >= 0 ? confirm_payment(item, change) : specify_amount_pending(item, change)
    else
      'Item not available'
    end
  end

  attr_reader :items
  attr_accessor :balance

  private

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

  def check_item_availability(item)
    if item && item.quantity > 0
      true
    else
      false
    end
  end

  def process_payment(item_price, amount) # TODO: Improve this logic to handle more use cases
    change = if amount >= item_price.cents
               calculate_change_to_give_user(amount,
                                             item_price)
             else
               calculate_difference_amount_pending(
                 amount, item_price
               )
             end
  end

  def calculate_change_to_give_user(amount, item_price)
    change_in_cents = amount > item_price.cents ? amount - item_price.cents : 0
    update_machine_balance(amount, change_in_cents)
    change_in_cents
  end

  def calculate_difference_amount_pending(amount, item_price)
    amount - item_price.cents
  end

  def update_machine_balance(amount, change_in_cents)
    new_balance_cents = @balance.amount.cents + amount - (change_in_cents || 0)
    @balance = Change.new(Money.new(new_balance_cents, 'GBP'))
  end
end
