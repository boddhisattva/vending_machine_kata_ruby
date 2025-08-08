# frozen_string_literal: true

require 'money'
require_relative 'payment_processor'
require_relative 'session_manager'
require_relative 'single_user_session_manager'
require_relative 'reload_manager'
require_relative 'change_validator'

# Vending machine class to handle item purchases and change
class VendingMachine
  attr_reader :items, :payment_processor
  attr_accessor :balance

  def initialize(items, balance, payment_processor = PaymentProcessor.new,
                 session_manager = SingleUserSessionManager.new,
                 reload_manager = ReloadManager.new)
    @items = items
    @balance = balance
    @payment_processor = payment_processor
    @session_manager = session_manager
    @reload_manager = reload_manager
    @change_validator = ChangeValidator.new
    @current_session_id = nil
    @items_index = build_items_index
  end

  # Keep existing interface for backward compatibility
  def purchase_item(item_name, payment)
    item = @items_index[item_name]

    result, @balance = payment_processor.process_payment(item, payment, items, balance)
    result
  end

  # New session-based interface
  def start_purchase(item_name)
    item = @items_index[item_name]
    return 'Item not found' unless item

    result = @session_manager.start_session(item)
    if result[:success]
      @current_session_id = result[:session_id]
      result[:message]
    else
      result[:message]
    end
  end

  def insert_payment(payment)
    return 'No active purchase session. Please start a purchase first.' unless @current_session_id

    result = @session_manager.add_payment(@current_session_id, payment)

    if result[:success] && result[:completed]
      complete_current_purchase
    else
      result[:message]
    end
  end

  def complete_purchase
    return 'No active purchase session' unless @current_session_id

    result = @session_manager.complete_session(@current_session_id)
    if result[:success]
      process_completed_session(result[:session])
    else
      result[:message]
    end
  end

  def cancel_purchase
    return 'No active purchase session' unless @current_session_id

    result = @session_manager.cancel_session(@current_session_id)
    @current_session_id = nil

    # Format the cancellation message with coins returned
    if result[:success] && result[:partial_payment]
      change_to_return = Change.new(result[:partial_payment])
      coins_returned = change_to_return.format_for_return
      if coins_returned.empty?
        'Purchase cancelled. No money to return.'
      else
        "Purchase cancelled. Money returned: #{coins_returned}"
      end
    else
      result[:message]
    end
  end

  def available_change
    @balance.respond_to?(:calculate_total_amount) ? @balance.calculate_total_amount : 0
  end

  def balance_in_english
    @balance.respond_to?(:to_english) ? @balance.to_english : 'No balance information'
  end

  def reload_change(coins_to_add)
    message, @balance = @reload_manager.reload_change(@balance, coins_to_add)
    message
  end

  def reload_item(item_name, quantity, price = nil)
    message, @items = @reload_manager.reload_item(@items, @items_index, item_name, quantity, price)
    rebuild_items_index # Rebuild index after items change
    message
  end

  def display_stock
    return 'No items available' if @items.empty?

    @items.map { |item| "#{item.name}: #{item.quantity} units @ €#{format('%.2f', item.price / 100.0)}" }.join("\n")
  end

  private

  def build_items_index
    @items.each_with_object({}) { |item, hash| hash[item.name] = item }
  end

  def rebuild_items_index
    @items_index = build_items_index
  end

  def complete_current_purchase
    # First check if we can make change before completing the session
    return 'No active purchase session' unless @current_session_id

    # Get the session to check change-making ability
    session = @session_manager.current_session

    # Validate if we can make change
    validation_error = @change_validator.validate_change_availability(
      session.accumulated_payment,
      session.item.price,
      @balance
    )

    return validation_error if validation_error

    # Now we can safely complete the purchase
    complete_purchase
  end

  def process_completed_session(session)
    # Process the payment through PaymentProcessor
    result, @balance = @payment_processor.process_payment(session.item, session.accumulated_payment, items, balance)

    # Clear the session
    @current_session_id = nil

    result
  end
end
