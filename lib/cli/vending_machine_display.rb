class VendingMachineDisplay
  def initialize(vending_machine, currency_formatter)
    @vending_machine = vending_machine
    @currency_formatter = currency_formatter
  end

  def show_welcome_message
    puts '=== Vending Machine CLI ==='
    puts 'Welcome! What would you like to purchase through the Vending machine?'
    puts
  end

  def show_menu_options
    puts 'Choose an option:'
    puts '1. Display available items'
    puts '2. Purchase item with session'
    puts '3. Display current balance'
    puts '4. Display machine status'
    puts '5. Reload items'
    puts '6. Reload change'
    puts 'q. Quit'
    print 'Enter your choice: '
  end

  def show_available_items
    puts "\n=== Available Items in the Vending Machine ==="
    @vending_machine.items.each_with_index do |item, index|
      price_display = @currency_formatter.format_item_price(item)
      puts "#{index + 1}. #{item.name} - #{price_display} (#{item.quantity} available)"
    end
  end

  def show_current_balance
    puts "\n=== Current Balance ==="
    puts "Available change: #{@currency_formatter.format_amount(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
  end

  def show_change_return_info
    puts "\n=== Return Change ==="
    puts 'Note: Change is automatically returned after each purchase.'
    puts "Available change in machine: #{@currency_formatter.format_amount(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
  end

  def show_machine_status
    puts "\n=== Machine Status ==="
    puts "Available change: #{@currency_formatter.format_amount(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
    puts
    puts 'Items in stock:'
    @vending_machine.items.each do |item|
      puts "  #{item.name}: #{item.quantity} units"
    end
  end

  def show_payment_instructions
    puts 'Format: Enter payment as a hash of coin denominations in cents'
    puts 'Example: {100 => 2, 25 => 1} means 2, 1 Euro coins(100 cents is 1 Euro) + 1 quarter = $2.25'
    puts 'Available denominations: 1, 2, 5, 10, 20, 50, 100, 200 cents'
  end

  def show_goodbye_message
    puts 'Goodbye!'
  end

  def show_invalid_choice_message
    puts 'Invalid choice. Please try again.'
  end
end
