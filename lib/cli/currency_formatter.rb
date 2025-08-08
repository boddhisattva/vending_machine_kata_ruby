class CurrencyFormatter
  def format_amount(amount_in_cents)
    euros = amount_in_cents / 100.0
    '€%.2f' % euros
  end

  def format_item_price(item)
    format_amount(item.price)
  end
end
