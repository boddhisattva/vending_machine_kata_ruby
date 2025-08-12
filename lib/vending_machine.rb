# frozen_string_literal: true

require_relative 'payment_processor'
require_relative 'session_manager'
require_relative 'single_user_session_manager'
require_relative 'item_loader'
require_relative 'change_reloader'
require_relative 'change_validator'

# Vending machine class to handle item purchases and change
class VendingMachine
  attr_reader :items, :payment_processor
  attr_accessor :balance

  def initialize(items, balance, payment_processor = PaymentProcessor.new,
                 session_manager = SingleUserSessionManager.new,
                 item_loader = nil, change_reloader = nil)
    @items = items
    @balance = balance
    @payment_processor = payment_processor
    @session_manager = session_manager
    @item_loader = item_loader || ItemLoader.new
    @change_reloader = change_reloader || ChangeReloader.new
    @change_validator = ChangeValidator.new
    @current_session_id = nil
    @items_index = build_items_index
  end

  # Session-based interface
  def start_purchase(item_name)
    item = @items_index[item_name]
    return 'Item not found' unless item
    return 'Item not available' unless item.quantity > 0

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
      # Check if we can make change BEFORE completing
      session = @session_manager.current_session
      validation_error = @change_validator.validate_change_availability(
        session.accumulated_payment,
        session.item.price,
        @balance
      )

      if validation_error
        # Auto-cancel and refund
        auto_cancel_with_refund('Cannot provide change.')
      else
        # Proceed with normal completion
        complete_current_purchase
      end
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
    message, @balance = @change_reloader.reload_change(@balance, coins_to_add)
    message
  end

  def load_item(item_name, quantity, price = nil)
    message, @items = @item_loader.load_item(@items, @items_index, item_name, quantity, price)
    rebuild_items_index # Rebuild index after items change
    message
  end

  def display_stock
    return 'No items available' if @items.empty?

    @items.map { |item| "#{item.name}: #{item.quantity} units @ €#{format('%.2f', item.price / 100.0)}" }.join("\n")
  end

  def item_exists?(item_name)
    @items_index.key?(item_name)
  end

  private

  def build_items_index
    @items.each_with_object({}) { |item, hash| hash[item.name] = item }
  end

  def rebuild_items_index
    @items_index = build_items_index
  end

  def auto_cancel_with_refund(reason)
    # Get the payment before cancelling
    session = @session_manager.current_session
    payment = session.accumulated_payment

    # Cancel the session
    result = @session_manager.cancel_session(@current_session_id)
    @current_session_id = nil

    # Format refund message
    if payment && !payment.empty?
      change_to_return = Change.new(payment)
      coins_returned = change_to_return.format_for_return
      "#{reason} Payment refunded: #{coins_returned}. Please try with exact amount."
    else
      "#{reason} No payment to refund."
    end
  end

  def complete_current_purchase
    return 'No active purchase session' unless @current_session_id

    # Change validation now happens in insert_payment, so just complete
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
