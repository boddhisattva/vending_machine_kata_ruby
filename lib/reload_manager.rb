# lib/reload_manager.rb

require_relative 'reload_validator'

class ReloadManager
  def initialize(reload_validator = ReloadValidator.new)
    @reload_validator = reload_validator
  end

  def reload_item(items, items_index, item_name, quantity, price = nil)
    validation_error = @reload_validator.validate_item_reload(items_index, item_name, quantity, price)
    return [validation_error, items] if validation_error

    existing_item = items_index[item_name]

    if existing_item
      existing_item.quantity += quantity
      message = "Successfully added #{quantity} units to #{item_name}. New quantity: #{existing_item.quantity}"
    else
      new_item = Item.new(item_name, price, quantity)
      items << new_item
      message = "Successfully added new item: #{item_name} - €#{format('%.2f', price / 100.0)} (#{quantity} units)"
    end

    [message, items]
  end

  def reload_change(balance, coins_to_add)
    validation_error = @reload_validator.validate_coin_reload(coins_to_add)
    return [validation_error, balance] if validation_error

    new_balance_hash = balance.amount.dup
    coins_to_add.each do |denomination, count|
      new_balance_hash[denomination] ||= 0
      new_balance_hash[denomination] += count
    end

    new_balance = Change.new(new_balance_hash)

    added_change = Change.new(coins_to_add)
    message = "Successfully added coins: #{added_change.to_english}. Total balance: €#{'%.2f' % new_balance.to_dollars}"

    [message, new_balance]
  end
end
