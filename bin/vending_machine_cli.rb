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
    setup_items_available_for_purchase
  end

  def run
    puts '=== Vending Machine CLI ==='
    puts 'Welcome! What would you like to purchase through the Vending machine?'
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
        puts 'Goodbye!'
        break
      else
        puts 'Invalid choice. Please try again.'
      end

      puts
    end
  end

  private

  def setup_items_available_for_purchase
    items = [
      Item.new('Coke', 150, 5),      # €1.50 = 150 cents
      Item.new('Chips', 100, 3),     # €1.00 = 100 cents
      Item.new('Candy', 75, 8),      # €0.75 = 75 cents
      Item.new('Water', 125, 2)      # €1.25 = 125 cents
    ]
    @vending_machine = VendingMachine.new(items, Change.new(INITIAL_BALANCE))
  end

  def display_menu
    puts 'Choose an option:'
    puts '1. Display available items'
    puts '2. Purchase item with session'
    puts '3. Display current balance'
    puts '4. Return change'
    puts '5. Display machine status'
    puts 'q. Quit'
    print 'Enter your choice: '
  end

  def get_user_choice
    input = gets
    return 'q' if input.nil?

    input.chomp.downcase
  end

  def safe_gets
    input = gets
    return nil if input.nil?

    input.chomp
  end

  def display_items
    puts "\n=== Available Items in the Vending Machine ==="
    @vending_machine.items.each_with_index do |item, index|
      price_in_euros = item.price / 100.0
      puts "#{index + 1}. #{item.name} - €#{price_in_euros} (#{item.quantity} available)"
    end
  end

  def display_balance
    puts "\n=== Current Balance ==="
    puts "Available change: #{format_currency(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
  end

  def return_change
    puts "\n=== Return Change ==="
    puts 'Note: Change is automatically returned after each purchase.'
    puts "Available change in machine: #{format_currency(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
  end

  def display_machine_status
    puts "\n=== Machine Status ==="
    puts "Available change: #{format_currency(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
    puts
    puts 'Items in stock:'
    @vending_machine.items.each do |item|
      puts "  #{item.name}: #{item.quantity} units"
    end
  end

  def format_currency(amount)
    '€%.2f' % amount
  end

  def purchase_with_session
    puts "\n=== Purchase Item with Session ==="
    display_items
    print 'Enter item number to purchase: '

    input = safe_gets
    return if input.nil?

    item_index = input.to_i - 1

    if item_index < 0 || item_index >= @vending_machine.items.length
      puts 'Invalid item number.'
      return
    end

    item = @vending_machine.items[item_index]
    price_in_euros = item.price / 100.0
    puts "Selected: #{item.name} - €#{price_in_euros}"
    puts
    puts 'Starting purchase session...'
    result = @vending_machine.start_purchase(item.name)
    puts result

    loop do
      puts
      puts 'Format: Enter payment as a hash of coin denominations in cents'
      puts 'Example: {100 => 2, 25 => 1} means 2, 1 Euro coins(100 cents is 1 Euro) + 1 quarter = $2.25'
      puts 'Available denominations: 1, 2, 5, 10, 20, 50, 100, 200 cents'
      print "Enter payment hash (or 'cancel' to cancel): "

      input = safe_gets
      return if input.nil?

      if input.downcase == 'cancel'
        puts @vending_machine.cancel_purchase
        break
      end

      begin
        payment = parse_payment_hash(input)
        next if payment.nil?

        result = @vending_machine.insert_payment(payment)
        puts result

        break if result.include?('Payment complete') || result.include?('Thank you for your purchase')
      rescue StandardError => e
        puts "Error parsing input: #{e.message}"
        puts 'Please use the format: {100 => 2, 25 => 1}'
      end
    end
  end

  def parse_payment_hash(input)
    # Remove whitespace and validate basic hash format
    clean_input = input.strip

    return nil unless input_looks_like_hash?(input)

    # Extract content between braces
    content = clean_input[/{(.*)}/m, 1]
    return {} if content.nil? || content.strip.empty?

    payment = {}

    # Split by commas and parse each key-value pair
    pairs = content.split(',').map(&:strip)

    pairs.each do |pair|
      # Match pattern like "100 => 2" or "100=>2"
      match = pair.match(/\A\s*(\d+)\s*=>\s*(\d+)\s*\z/)

      unless match
        puts "Invalid pair format: '#{pair}'. Expected format: 'denomination => count'"
        return nil
      end

      denomination = match[1].to_i
      count = match[2].to_i

      if count <= 0
        puts "Invalid count: #{count}. Count must be positive."
        return nil
      end

      payment[denomination] = count
    end

    payment
  rescue StandardError => e
    puts "Error parsing payment hash: #{e.message}"
    puts 'Please use the format: {100 => 2, 25 => 1}'
    nil
  end

  def input_looks_like_hash?(input)
    clean_input = input.strip

    unless clean_input.start_with?('{') && clean_input.end_with?('}')
      puts 'Invalid format. Input must be in hash format like {100 => 2, 50 => 1}'
      return false
    end

    true
  end
end

if __FILE__ == $0
  cli = VendingMachineCLI.new
  cli.run
end
