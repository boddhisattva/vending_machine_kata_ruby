class ItemSelector
  def initialize(vending_machine, currency_formatter)
    @vending_machine = vending_machine
    @currency_formatter = currency_formatter
  end

  def select_item_for_purchase(item_number)
    item = find_item_by_number(item_number)
    return nil unless item

    show_selected_item_details(item)
    item
  end

  private

  def find_item_by_number(item_number)
    item_index = item_number - 1

    if item_index_is_invalid?(item_index)
      puts 'Invalid item number.'
      return nil
    end

    @vending_machine.items[item_index]
  end

  def item_index_is_invalid?(index)
    index < 0 || index >= @vending_machine.items.length
  end

  def show_selected_item_details(item)
    price_display = @currency_formatter.format_item_price(item)
    puts "Selected: #{item.name} - #{price_display}"
    puts
  end
end
