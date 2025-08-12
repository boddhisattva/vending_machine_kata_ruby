class ItemLoadHandler
  def initialize(vending_machine, display, input_handler)
    @vending_machine = vending_machine
    @display = display
    @input_handler = input_handler
  end

  def load_items_for_machine
    show_current_stock_status

    item_name = ask_for_item_name
    return unless item_name

    quantity = ask_for_quantity_to_add
    return unless quantity

    add_items_to_machine(item_name, quantity)
  end

  private

  def show_current_stock_status
    puts "\n=== Reload or Add New Items ==="
    puts 'Current stock:'
    puts @vending_machine.display_stock
    puts
  end

  def ask_for_item_name
    print 'Enter item name: '
    @input_handler.safe_gets
  end

  def ask_for_quantity_to_add
    print 'Enter quantity to add: '
    input = @input_handler.safe_gets
    return nil if input.nil?

    input.to_i  # Return the integer value, even if 0 or negative (let vending_machine validate)
  end

  def add_items_to_machine(item_name, quantity)
    if item_already_exists?(item_name)
      reload_existing_item(item_name, quantity)
    else
      add_new_item_with_price(item_name, quantity)
    end
  end

  def item_already_exists?(item_name)
    @vending_machine.items.any? { |item| item.name == item_name }
  end

  def reload_existing_item(item_name, quantity)
    result = @vending_machine.load_item(item_name, quantity)
    puts result
  end

  def add_new_item_with_price(item_name, quantity)
    price = ask_for_item_price
    return unless price

    result = @vending_machine.load_item(item_name, quantity, price)
    puts result
  end

  def ask_for_item_price
    print 'New item detected. Enter price in cents (e.g., 150 for €1.50): '
    input = @input_handler.safe_gets
    return nil if input.nil?

    input.to_i  # Return the integer value, even if 0 or negative (let vending_machine validate)
  end
end
