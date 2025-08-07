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

    item = let_user_select_item
    return unless item

    show_selected_item_details(item)
    start_purchase_session_for(item)
    collect_payment_until_complete
  end

  def let_user_select_item
    display_items
    item_number = ask_for_item_number
    return nil unless item_number

    find_item_by_number(item_number)
  end

  def ask_for_item_number
    print 'Enter item number to purchase: '
    input = safe_gets
    return nil if input.nil?

    input.to_i
  end

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
    price_in_euros = item.price / 100.0
    puts "Selected: #{item.name} - €#{price_in_euros}"
    puts
  end

  def start_purchase_session_for(item)
    puts 'Starting purchase session...'
    result = @vending_machine.start_purchase(item.name)
    puts result
  end

  def collect_payment_until_complete
    loop do
      payment_input = request_payment_from_user
      return if payment_input.nil?

      if user_wants_to_cancel?(payment_input)
        cancel_current_purchase
        break
      end

      break if process_payment_input(payment_input)
    end
  end

  def request_payment_from_user
    puts
    show_payment_instructions
    print "Enter payment hash (or 'cancel' to cancel): "
    safe_gets
  end

  def show_payment_instructions
    puts 'Format: Enter payment as a hash of coin denominations in cents'
    puts 'Example: {100 => 2, 25 => 1} means 2, 1 Euro coins(100 cents is 1 Euro) + 1 quarter = $2.25'
    puts 'Available denominations: 1, 2, 5, 10, 20, 50, 100, 200 cents'
  end

  def user_wants_to_cancel?(input)
    input.downcase == 'cancel'
  end

  def cancel_current_purchase
    puts @vending_machine.cancel_purchase
  end

  def process_payment_input(input)
    payment = parse_payment_hash(input)
    return false if payment.nil?

    insert_payment_and_check_if_complete(payment)
  rescue StandardError => e
    show_payment_error(e)
    false
  end

  def insert_payment_and_check_if_complete(payment)
    result = @vending_machine.insert_payment(payment)
    puts result
    payment_is_complete?(result)
  end

  def payment_is_complete?(result)
    result.include?('Payment complete') || result.include?('Thank you for your purchase')
  end

  def show_payment_error(error)
    puts "Error parsing input: #{error.message}"
    puts 'Please use the format: {100 => 2, 25 => 1}'
  end

  def parse_payment_hash(input)
    return nil unless input_looks_like_hash?(input)

    content = extract_hash_content(input)
    return {} if content_is_empty?(content)

    build_payment_from_content(content)
  rescue StandardError => e
    show_parsing_error(e)
    nil
  end

  def extract_hash_content(input)
    input.strip[/{(.*)}/m, 1]
  end

  def content_is_empty?(content)
    content.nil? || content.strip.empty?
  end

  def build_payment_from_content(content)
    payment = {}
    coin_entries = split_into_coin_entries(content)

    coin_entries.each do |entry|
      denomination, count = parse_single_coin_entry(entry)
      return nil unless denomination && count

      return nil unless count_is_valid?(count)

      payment[denomination] = count
    end

    payment
  end

  def split_into_coin_entries(content)
    content.split(',').map(&:strip)
  end

  def parse_single_coin_entry(entry)
    match = entry.match(/\A\s*(\d+)\s*=>\s*(\d+)\s*\z/)

    unless match
      puts "Invalid pair format: '#{entry}'. Expected format: 'denomination => count'"
      return [nil, nil]
    end

    [match[1].to_i, match[2].to_i]
  end

  def count_is_valid?(count)
    if count <= 0
      puts "Invalid count: #{count}. Count must be positive."
      return false
    end

    true
  end

  def show_parsing_error(error)
    puts "Error parsing payment hash: #{error.message}"
    puts 'Please use the format: {100 => 2, 25 => 1}'
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
