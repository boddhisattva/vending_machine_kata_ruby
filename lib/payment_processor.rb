class PaymentProcessor
  def initialize(payment_validator = PaymentValidator.new)
    @payment_validator = payment_validator
  end

  def process_payment(item, payment, items, balance)
    @balance = balance  # Store the balance as instance variable
    # TODO: Consider later if @balance needs to be an instance variable or a local variable/parameter

    validation_result = @payment_validator.validate_purchase
    #TODO: Improve further aftewards for success , return true and also method name refactor to purcchase_valid?(item, payment, @balance)
    return validation_result unless validation_result.nil?

    total_payment_for_item = payment.sum { |denom, count| denom * count }

    payment_validation = @payment_validator.validate_payment_amount(item, total_payment_for_item, @balance)
    return payment_validation unless payment_validation.nil?

    process_transaction(item, payment, total_payment_for_item)
  end

  private

  def process_transaction(item, payment, total_payment_for_item)
    change = process_change_transaction(item, payment, total_payment_for_item)

    if change >= 0
      complete_successful_transaction(item, change)
    else
      [specify_amount_pending(item, change), @balance]
    end
  end

  def process_change_transaction(item, payment, total_payment_for_item)
    change_in_cents = total_payment_for_item > item.price ? total_payment_for_item - item.price : 0
    update_machine_balance(payment, change_in_cents)
    change_in_cents
  end

  def complete_successful_transaction(item, change)
    item.quantity -= 1
    [confirm_payment(item, change), @balance]
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
