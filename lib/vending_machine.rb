require 'money'

class VendingMachine
  def initialize(items, balance, payment_processor = PaymentProcessor.new)
    @items = items
    @balance = balance
    @payment_processor = payment_processor
  end

  def purchase_item(item_name, payment)
    item = items.find { |item| item.name == item_name }

    result, @balance = payment_processor.process_payment(item, payment, items, balance)
    result
  end

  attr_reader :items, :payment_processor
  attr_accessor :balance
end
