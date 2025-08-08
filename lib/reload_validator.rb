# lib/reload_validator.rb

class ReloadValidator
  def validate_item_reload(items_index, item_name, quantity, price = nil)
    return 'Invalid item name' if item_name.nil? || item_name.to_s.strip.empty?

    return 'Invalid quantity. Please provide a positive number.' unless quantity.is_a?(Integer) && quantity > 0

    existing_item = items_index[item_name]

    return 'Price required for new item' if existing_item.nil? && price.nil?

    return 'Invalid price. Price must be positive.' if !existing_item && price && (!price.is_a?(Integer) || price <= 0)

    nil
  end

  def validate_coin_reload(coins)
    return 'Invalid input. Please provide a hash of coins.' unless coins.is_a?(Hash)
    return 'Invalid input. All quantities must be positive.' unless coins.values.all? { |v| v.is_a?(Integer) && v > 0 }

    invalid_denoms = coins.keys - Change::ACCEPTABLE_COINS
    return "Invalid coin denominations: #{invalid_denoms}" if invalid_denoms.any?

    nil
  end
end
