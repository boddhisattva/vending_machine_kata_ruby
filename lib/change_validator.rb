# frozen_string_literal: true

# Validates if exact change can be made for a transaction
class ChangeValidator
  def initialize(change_calculator = ChangeCalculator.new)
    @change_calculator = change_calculator
  end

  def validate_change_availability(payment, item_price, current_balance)
    return nil if can_make_change?(payment, item_price, current_balance)

    "Cannot provide change with available coins. Please type 'cancel' to get refund and to restart purchase attempt with the exact amount"
  end

  private

  def can_make_change?(payment, item_price, current_balance)
    change_needed = payment.sum { |denom, count| denom * count } - item_price
    return true if change_needed <= 0 # No change needed or exact payment

    # Simulate adding payment to balance
    test_balance = current_balance.amount.dup
    payment.each do |denom, count|
      test_balance[denom] ||= 0
      test_balance[denom] += count
    end

    # Check if we can make exact change
    @change_calculator.can_make_exact_change?(test_balance, change_needed)
  end
end
