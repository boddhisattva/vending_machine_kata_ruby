require_relative 'payment_validator'

class PaymentProcessor
  def initialize(payment_validator = PaymentValidator.new)
    @payment_validator = payment_validator
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

    if change_given.nil? && change_in_cents > 0
      # Cannot make change
      return ['Cannot provide change with available coins. Please use exact amount.', @balance]
    end

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

  # Returns [change_given_hash, new_balance_hash] or [nil, original_balance] if cannot make change
  def make_change(balance, change_amount)
    return [{}, balance] if change_amount == 0

    remaining = change_amount
    change_given = {}
    new_balance = balance.dup
    Change::ACCEPTABLE_COINS.sort.reverse.each do |denomination|
      next if remaining <= 0

      available = new_balance[denomination] || 0
      num = [available, remaining.div(denomination)].min
      next unless num > 0

      change_given[denomination] = num
      new_balance[denomination] -= num
      remaining -= num * denomination
    end
    if remaining == 0
      # Remove zero-quantity coins
      new_balance.reject! { |_, qty| qty <= 0 }
      [change_given, new_balance]
    else
      [nil, balance] # Cannot make change
    end
  end
end
