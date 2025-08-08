require 'money'
require_relative 'payment_processor'
require_relative 'session_manager'
require_relative 'single_user_session_manager'

class VendingMachine
  attr_reader :items, :payment_processor
  attr_accessor :balance

  def initialize(items, balance, payment_processor = PaymentProcessor.new,
                 session_manager = SingleUserSessionManager.new)
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
    result[:message]
  end

  def available_change
    @balance.respond_to?(:to_dollars) ? @balance.to_dollars : 0
  end

  def balance_in_english
    @balance.respond_to?(:to_english) ? @balance.to_english : 'No balance information'
  end

  # Reload items - adds stock to existing items or adds new items
  def reload_item(item_name, quantity_to_add, price = nil)
    unless quantity_to_add.is_a?(Integer) && quantity_to_add > 0
      return 'Invalid quantity. Please provide a positive number.'
    end

    existing_item = items.find { |item| item.name == item_name }

    if existing_item
      # Add to existing item's quantity
      existing_item.quantity += quantity_to_add
      "Successfully added #{quantity_to_add} units to #{item_name}. New quantity: #{existing_item.quantity}"
    else
      # Add new item if price is provided
      return 'Price required for new item' unless price
      return 'Invalid price. Please provide a positive number.' unless price.is_a?(Integer) && price > 0

      new_item = Item.new(item_name, price, quantity_to_add)
      @items << new_item
      "Successfully added new item: #{item_name} - €#{format('%.2f', price / 100.0)} (#{quantity_to_add} units)"
    end
  end

  # Reload change - adds coins to the machine's balance
  def reload_change(coins_to_add)
    return 'Invalid input. Please provide a hash of coins.' unless coins_to_add.is_a?(Hash)
    return 'Invalid input. All quantities must be positive.' unless coins_to_add.values.all? do |v|
      v.is_a?(Integer) && v > 0
    end

    # Validate denominations
    invalid_denoms = coins_to_add.keys - Change::ACCEPTABLE_COINS
    return "Invalid coin denominations: #{invalid_denoms}" if invalid_denoms.any?

    # Merge new coins with existing balance
    new_balance_hash = @balance.amount.dup
    coins_to_add.each do |denomination, count|
      new_balance_hash[denomination] ||= 0
      new_balance_hash[denomination] += count
    end

    # Create new Change object to ensure validation
    @balance = Change.new(new_balance_hash)

    added_change = Change.new(coins_to_add)
    "Successfully added coins: #{added_change.to_english}. Total balance: €#{'%.2f' % @balance.to_dollars}"
  end

  def display_stock
    return 'No items available' if @items.empty?

    @items.map { |item| "#{item.name}: #{item.quantity} units @ €#{format('%.2f', item.price / 100.0)}" }.join("\n")
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
