class ChangeReloader
  def initialize(vending_machine, currency_formatter, payment_parser, input_handler)
    @vending_machine = vending_machine
    @currency_formatter = currency_formatter
    @payment_parser = payment_parser
    @input_handler = input_handler
  end

  def reload_change_for_machine
    show_current_balance_status
    show_coin_entry_instructions

    coins_to_add = get_coins_from_user
    return unless coins_to_add

    add_coins_to_machine(coins_to_add)
  end

  private

  def show_current_balance_status
    puts "\n=== Reload Change ==="
    puts "Current balance: #{@currency_formatter.format_amount(@vending_machine.available_change)}"
    puts "Coins: #{@vending_machine.balance_in_english}"
    puts
  end

  def show_coin_entry_instructions
    puts 'Format: Enter coins as a hash of denominations in cents'
    puts 'Example: {100 => 5, 50 => 10} means 5 €1 coins and 10 50-cent coins'
    puts 'Available denominations: 1, 2, 5, 10, 20, 50, 100, 200 cents'
  end

  def get_coins_from_user
    print 'Enter coins to add: '
    input = @input_handler.safe_gets
    return nil if input.nil?

    parse_coin_input(input)
  end

  def parse_coin_input(input)
    coins = @payment_parser.parse(input)

    if coins.nil?
      show_invalid_format_message
      return nil
    end

    coins
  end

  def show_invalid_format_message
    puts 'Invalid format. Please use a hash format like {100 => 5, 50 => 10}'
  end

  def add_coins_to_machine(coins)
    result = @vending_machine.reload_change(coins)
    puts result
  end
end
