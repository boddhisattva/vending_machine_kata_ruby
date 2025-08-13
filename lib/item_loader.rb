require_relative 'reload_validator'

class ItemLoader
  def initialize(reload_validator = ReloadValidator.new)
    @reload_validator = reload_validator
  end

  def load_item(items, items_index, item_name, quantity, price = nil)
    validation_error = @reload_validator.validate_item_reload(items_index, item_name, quantity, price)
    return [validation_error, items] if validation_error

    existing_item = items_index[item_name]

    if existing_item
      load_existing_item(existing_item, item_name, quantity, items)
    else
      add_new_item(items, item_name, price, quantity)
    end
  end

  private

  def load_existing_item(existing_item, item_name, quantity, items)
    existing_item.quantity += quantity
    message = "Successfully added #{quantity} units to #{item_name}. New quantity: #{existing_item.quantity}"
    [message, items]
  end

  def add_new_item(items, item_name, price, quantity)
    new_item = Item.new(item_name, price, quantity)
    items << new_item
    message = "Successfully added new item: #{item_name} - €#{format('%.2f', price / 100.0)} (#{quantity} units)"
    [message, items]
  end
end
