# frozen_string_literal: true

class PurchaseExecutor
  def initialize(display, input_handler, item_selector, purchase_orchestrator)
    @display = display
    @input_handler = input_handler
    @item_selector = item_selector
    @purchase_orchestrator = purchase_orchestrator
  end

  def execute
    puts "\n=== Purchase Item with Session ==="
    @display.show_available_items

    item_number = @input_handler.get_item_number
    return unless item_number

    item = @item_selector.select_item_for_purchase(item_number)
    return unless item

    @purchase_orchestrator.execute_purchase_for(item)
  end
end
