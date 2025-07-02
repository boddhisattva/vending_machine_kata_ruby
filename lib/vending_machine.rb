require 'money'

class VendingMachine
  def initialize(items, balance)
    @items = items
    @balance = balance
  end

  def select_item(item_name, amount)
    item = items.find { |item| item.name == item_name }
    if check_item_availability(item) && balance.amount >= item.price && item.quantity > 0
      change = process_payment(item.price, amount)
      [item.name, change.amount.cents, 'Thank you for your purchase!'] # TODO: adapt accordingly if change given how much amount and similarly other messages
    else
      'Item not available'
    end
  end

  attr_reader :items
  attr_accessor :balance

  private

  def check_item_availability(item)
    if item && item.quantity > 0
      true
    else
      false
    end
  end

  def process_payment(item_price, amount) # TODO: Improve this logic to handle more use cases
    change_to_give_user = calculate_change_to_give_user(amount, item_price)
    update_machine_balance(amount, change_to_give_user.amount.cents)
    change_to_give_user
  end

  def calculate_change_to_give_user(amount, item_price)
    change_in_cents = amount > item_price.cents ? amount - item_price.cents : 0
    change_in_cents > 0 ? Change.new(Money.new(change_in_cents, 'GBP')) : Change.new(Money.new(0, 'GBP'))
  end

  def update_machine_balance(amount, change_in_cents)
    new_balance_cents = @balance.amount.cents + amount - (change_in_cents || 0)
    @balance = Change.new(Money.new(new_balance_cents, 'GBP'))
  end
end
