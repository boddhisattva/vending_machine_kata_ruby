# frozen_string_literal: true

class MenuRouter
  def initialize(display, item_reloader, change_reloader, purchase_executor)
    @display = display
    @item_reloader = item_reloader
    @change_reloader = change_reloader
    @purchase_executor = purchase_executor
  end

  def route(choice)
    case choice
    when '1'
      @display.show_available_items
    when '2'
      @purchase_executor.execute
    when '3'
      @display.show_current_balance
    when '4'
      @display.show_machine_status
    when '5'
      @item_reloader.reload_items_for_machine
    when '6'
      @change_reloader.reload_change_for_machine
    when 'q', 'quit', 'exit'
      @display.show_goodbye_message
    else
      @display.show_invalid_choice_message
    end
  end

  def quit_command?(choice)
    %w[q quit exit].include?(choice)
  end
end
