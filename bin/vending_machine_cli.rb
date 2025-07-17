#!/usr/bin/env ruby

require_relative '../lib/vending_machine'
require_relative '../lib/item'
require_relative '../lib/change'

class VendingMachineCLI
  INITIAL_BALANCE = {
    50 => 6,
    10 => 10,
    20 => 10,
    100 => 2,
    200 => 1,
    5 => 10,
    2 => 10,
    1 => 2
  }

  def initialize
    @vending_machine = VendingMachine.new([], Change.new(INITIAL_BALANCE))
    setup_items
  end

  def run
    puts "=== Vending Machine CLI ==="
    puts "Welcome! Let's test the vending machine functionality."
    puts

    loop do
      display_menu
      choice = get_user_choice

      case choice
      when '1'
        display_items
      when '2'
        purchase_with_session
      when '3'
        display_balance
      when '4'
        return_change
      when '5'
        display_machine_status
      when 'q', 'quit', 'exit'
        puts "Goodbye!"
        break
      else
        puts "Invalid choice. Please try again."
      end

      puts
    end
  end

  private

  def setup_items
    items = [
      Item.new("Coke", 1.50, 5),
      Item.new("Chips", 1.00, 3),
      Item.new("Candy", 0.75, 8),
      Item.new("Water", 1.25, 2)
    ]
    @vending_machine = VendingMachine.new(items, Change.new(INITIAL_BALANCE))
  end

  def display_menu
    puts "Choose an option:"
    puts "1. Display available items"
    puts "2. Purchase item with session (recommended)"
    puts "3. Display current balance"
    puts "4. Return change"
    puts "5. Display machine status"
    puts "q. Quit"
    print "Enter your choice: "
  end

  def get_user_choice
    input = gets
    return 'q' if input.nil?  # Handle EOF (Ctrl+D)
    input.chomp.downcase
  end

  def safe_gets
    input = gets
    return nil if input.nil?  # Handle EOF (Ctrl+D)
    input.chomp
  end

  def display_items
    puts "\n=== Available Items ==="
    @vending_machine.items.each_with_index do |item, index|
      puts "#{index + 1}. #{item.name} - $#{item.price} (#{item.quantity} available)"
    end
  end

  def insert_coins
    puts "\n=== Insert Coins (Legacy Method) ==="
    puts "Format: Enter payment as a hash of coin denominations in cents"
    puts "Example: {100 => 2, 25 => 1} means 2, 1 Euro coins(100 cents is 1 Euro) + 1 quarter = $2.25"
    puts "Available denominations: 1, 2, 5, 10, 20, 50, 100, 200 cents"
    puts
    print "Enter payment hash (e.g., {100 => 2}): "

    input = safe_gets
    return if input.nil?

    begin
      payment = eval(input)
      unless payment.is_a?(Hash) && payment.values.all? { |v| v.is_a?(Integer) && v > 0 }
        puts "Invalid format. Please use a hash with positive integer values."
        return
      end

      # Validate denominations
      valid_denoms = [1, 2, 5, 10, 20, 50, 100, 200]
      invalid_denoms = payment.keys.reject { |k| valid_denoms.include?(k) }
      if invalid_denoms.any?
        puts "Invalid denominations: #{invalid_denoms.join(', ')}. Valid: #{valid_denoms.join(', ')}"
        return
      end

      result = @vending_machine.purchase_item("Coke", payment)  # This is just for testing the payment
      puts "Payment processed successfully!"
      puts "Result: #{result}"
    rescue => e
      puts "Error parsing input: #{e.message}"
      puts "Please use the format: {100 => 2, 25 => 1}"
    end
  end

  def purchase_item
    puts "\n=== Purchase Item (Legacy Method) ==="
    display_items
    print "Enter item number to purchase: "

    input = safe_gets
    return if input.nil?

    item_index = input.to_i - 1

    if item_index < 0 || item_index >= @vending_machine.items.length
      puts "Invalid item number."
      return
    end

    item = @vending_machine.items[item_index]
    puts "Selected: #{item.name} - $#{item.price}"
    puts
    puts "Format: Enter payment as a hash of coin denominations in cents"
    puts "Example: {100 => 2, 25 => 1} means 2, 1 Euro coins(100 cents is 1 Euro) + 1 quarter = $2.25"
    puts "Available denominations: 1, 2, 5, 10, 20, 50, 100, 200 cents"
    print "Enter payment hash: "

    input = safe_gets
    return if input.nil?

    begin
      payment = eval(input)
      unless payment.is_a?(Hash) && payment.values.all? { |v| v.is_a?(Integer) && v > 0 }
        puts "Invalid format. Please use a hash with positive integer values."
        return
      end

      result = @vending_machine.purchase_item(item.name, payment)
      puts "Result: #{result}"
    rescue => e
      puts "Error parsing input: #{e.message}"
      puts "Please use the format: {100 => 2, 25 => 1}"
    end
  end

  def purchase_with_session
    puts "\n=== Purchase Item with Session (New Method) ==="
    display_items
    print "Enter item number to purchase: "

    input = safe_gets
    return if input.nil?

    item_index = input.to_i - 1

    if item_index < 0 || item_index >= @vending_machine.items.length
      puts "Invalid item number."
      return
    end

    item = @vending_machine.items[item_index]
    puts "Selected: #{item.name} - $#{item.price}"
    puts
    puts "Starting purchase session..."
    result = @vending_machine.start_purchase(item.name)
    puts result

    loop do
      puts
      puts "Format: Enter payment as a hash of coin denominations in cents"
      puts "Example: {100 => 2, 25 => 1} means 2, 1 Euro coins(100 cents is 1 Euro) + 1 quarter = $2.25"
      puts "Available denominations: 1, 2, 5, 10, 20, 50, 100, 200 cents"
      print "Enter payment hash (or 'cancel' to cancel): "

      input = safe_gets
      return if input.nil?

      if input.downcase == 'cancel'
        puts @vending_machine.cancel_purchase
        break
      end

      begin
        payment = eval(input)
        unless payment.is_a?(Hash) && payment.values.all? { |v| v.is_a?(Integer) && v > 0 }
          puts "Invalid format. Please use a hash with positive integer values."
          next
        end

        result = @vending_machine.insert_payment(payment)
        puts result

        if result.include?("Payment complete") || result.include?("Thank you for your purchase")
          break
        end
      rescue => e
        puts "Error parsing input: #{e.message}"
        puts "Please use the format: {100 => 2, 25 => 1}"
      end
    end
  end

  def display_balance
    puts "\n=== Current Balance ==="
    puts "Available change: #{format_currency(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
  end

  def return_change
    puts "\n=== Return Change ==="
    puts "Note: Change is automatically returned after each purchase."
    puts "Available change in machine: #{format_currency(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
  end

  def display_machine_status
    puts "\n=== Machine Status ==="
    puts "Available change: #{format_currency(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
    puts
    puts "Items in stock:"
    @vending_machine.items.each do |item|
      puts "  #{item.name}: #{item.quantity} units"
    end
  end

  def format_currency(amount)
    "€%.2f" % amount
  end
end

if __FILE__ == $0
  cli = VendingMachineCLI.new
  cli.run
end
