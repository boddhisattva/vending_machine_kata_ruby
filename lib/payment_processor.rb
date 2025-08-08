require_relative 'payment_validator'
require_relative 'change_calculator'

class PaymentProcessor
  def initialize(payment_validator = PaymentValidator.new, change_calculator = ChangeCalculator.new)
    @payment_validator = payment_validator
    @change_calculator = change_calculator
  end

  def process_payment(item, payment, _items, balance)
    @balance = balance # Store the balance as instance variable
    # TODO: Consider later if @balance needs to be an instance variable or a local variable/parameter

    validation_result = @payment_validator.validate_purchase(item, payment, @balance)
    return validation_result unless validation_result.nil?

    total_payment_for_item = payment.sum { |denom, count| denom * count }

    payment_validation = @payment_validator.validate_payment_amount(item, total_payment_for_item, @balance)
    return payment_validation unless payment_validation.nil?

    process_transaction(item, payment, total_payment_for_item)
  end

  private

  def process_transaction(item, payment, total_payment_for_item)
    item_price_in_cents = item.price
    change_in_cents = total_payment_for_item > item_price_in_cents ? total_payment_for_item - item_price_in_cents : 0

    # Add the payment coins to the machine's balance (simulate before confirming)
    new_balance = @balance.amount.dup
    payment.each do |denom, count|
      new_balance[denom] ||= 0
      new_balance[denom] += count
    end

    # Try to make change
    change_given, updated_balance = make_change(new_balance, change_in_cents)

    # Update the machine's balance
    @balance = Change.new(updated_balance)
    item.quantity -= 1
    [confirm_payment(item, change_given), @balance]
  end

  def confirm_payment(item, change_given)
    if change_given && !change_given.empty?
      change_str = change_given.sort_by { |k, _| -k }
                               .select { |_, count| count > 0 }
                               .map { |denom, count| "#{count.to_i} x #{denom}c" }.join(', ')
      "Thank you for your purchase of #{item.name}. Please collect your item and change: #{change_str}"
    else
      "Thank you for your purchase of #{item.name}. Please collect your item."
    end
  end

  # Delegates to ChangeCalculator for change-making logic
  def make_change(balance, change_amount)
    @change_calculator.make_change(balance, change_amount)
  end
end
