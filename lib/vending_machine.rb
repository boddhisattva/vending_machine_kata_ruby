require 'money'
require_relative 'payment_processor'
require_relative 'session_manager'
require_relative 'single_user_session_manager'

class VendingMachine
  attr_reader :items, :payment_processor
  attr_accessor :balance

  def initialize(items, balance, payment_processor = PaymentProcessor.new, session_manager = SingleUserSessionManager.new)
    @items = items
    @balance = balance
    @payment_processor = payment_processor
    @session_manager = session_manager
    @current_session_id = nil
  end

  # Keep existing interface for backward compatibility
  def purchase_item(item_name, payment)
    item = items.find { |item| item.name == item_name }

    result, @balance = payment_processor.process_payment(item, payment, items, balance)
    result
  end

  # New session-based interface
  def start_purchase(item_name)
    item = items.find { |item| item.name == item_name }
    return "Item not found" unless item

    result = @session_manager.start_session(item)
    if result[:success]
      @current_session_id = result[:session_id]
      result[:message]
    else
      result[:message]
    end
  end

  def insert_payment(payment)
    return "No active purchase session. Please start a purchase first." unless @current_session_id

    result = @session_manager.add_payment(@current_session_id, payment)

    if result[:success] && result[:completed]
      complete_current_purchase
    else
      result[:message]
    end
  end

  def complete_purchase
    return "No active purchase session" unless @current_session_id

    result = @session_manager.complete_session(@current_session_id)
    if result[:success]
      process_completed_session(result[:session])
    else
      result[:message]
    end
  end

  def cancel_purchase
    return "No active purchase session" unless @current_session_id

    result = @session_manager.cancel_session(@current_session_id)
    @current_session_id = nil
    result[:message]
  end

  def available_change
    @balance.respond_to?(:to_dollars) ? @balance.to_dollars : 0
  end

  def balance_in_english
    @balance.respond_to?(:to_english) ? @balance.to_english : "No balance information"
  end

  private

  def complete_current_purchase
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
