class PaymentValidator
  def validate_purchase(item, payment, balance)
    return ['Item not available', balance] unless item_available?(item)
    return validate_payment_denominations(payment, balance) unless payment_denominations_valid?(payment)

    nil
  end

  def validate_payment_amount(item, total_payment_for_item, balance)
    unless total_payment_for_item >= item.price
      return [specify_amount_pending(item, total_payment_for_item - item.price),
              balance]
    end

    nil
  end

  private

  def validate_payment_denominations(payment, balance)
    invalid_denominations = payment.keys - Change::ACCEPTABLE_COINS
    ["Invalid coin denomination in payment: #{invalid_denominations}", balance]
  end

  def payment_denominations_valid?(payment)
    payment.keys.all? { |denom| Change::ACCEPTABLE_COINS.include?(denom) }
  end

  def item_available?(item)
    item && item.quantity > 0
  end

  def specify_amount_pending(item, change)
    "You need to pay #{change.abs} more cents to purchase #{item.name}"
  end
end
