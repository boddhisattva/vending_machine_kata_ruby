class PurchaseSessionOrchestrator
  def initialize(vending_machine, payment_parser, display, input_handler)
    @vending_machine = vending_machine
    @payment_parser = payment_parser
    @display = display
    @input_handler = input_handler
  end

  def execute_purchase_for(item)
    start_purchase_session_for(item)
    collect_payment_until_complete
  end

  private

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
    @display.show_payment_instructions
    @input_handler.get_payment_input
  end

  def user_wants_to_cancel?(input)
    input.downcase == 'cancel'
  end

  def cancel_current_purchase
    puts @vending_machine.cancel_purchase
  end

  def process_payment_input(input)
    payment = @payment_parser.parse(input)
    return false if payment.nil?

    insert_payment_and_check_if_complete(payment)
  rescue StandardError => e
    show_payment_error(e)
    false
  end

  def insert_payment_and_check_if_complete(payment)
    result = @vending_machine.insert_payment(payment)
    puts result
    payment_is_complete?(result) || payment_change_cannot_be_processed?(result)
  end

  def payment_is_complete?(result)
    result.include?('Payment complete') ||
      result.include?('Thank you for your purchase')
  end

  def payment_change_cannot_be_processed?(result)
    # Change cannot be processed related Auto-cancel with refund scenario
    result.include?('Payment refunded:')
  end

  def show_payment_error(error)
    puts "Error processing payment: #{error.message}"
    puts 'Please use the format: {100 => 2, 25 => 1}'
  end
end
