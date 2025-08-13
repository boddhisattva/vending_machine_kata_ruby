require_relative 'change_calculator'

class PaymentProcessor
  def initialize(change_calculator = ChangeCalculator.new)
    @change_calculator = change_calculator
  end

  def process_payment(item, payment, balance)
    total_payment_for_item = payment.sum { |denom, count| denom * count }
    process_transaction(item, payment, total_payment_for_item, balance)
  end

  private

  def process_transaction(item, payment, total_payment_for_item, balance)
    item_price_in_cents = item.price
    change_in_cents = total_payment_for_item > item_price_in_cents ? total_payment_for_item - item_price_in_cents : 0

    # Add the payment coins to the machine's balance (simulate before confirming)
    new_balance = balance.amount.dup
    payment.each do |denom, count|
      new_balance[denom] ||= 0
      new_balance[denom] += count
    end

    # Try to make change
    change_given, updated_balance = make_change(new_balance, change_in_cents)

    # Create updated balance object
    updated_balance_obj = Change.new(updated_balance)
    item.quantity -= 1
    [confirm_payment(item, change_given), updated_balance_obj]
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
