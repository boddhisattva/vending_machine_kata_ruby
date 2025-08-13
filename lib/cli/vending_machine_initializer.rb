class VendingMachineInitializer
  # Initial Balance Euro 10,72 --> 50 * 10 + 10 * 10 + 20  * 10 + 2 * 100 + 5* 10 + 2 * 10 + 1 * 2

  INITIAL_BALANCE = {
    50 => 6,
    10 => 10,
    20 => 10,
    100 => 2,
    200 => 1,
    5 => 10,
    2 => 10,
    1 => 2
  }.freeze

  INITIAL_ITEMS = [
    { name: 'Coke', price: 150, quantity: 5 },
    { name: 'Chips', price: 100, quantity: 3 },
    { name: 'Candy', price: 75, quantity: 8 },
    { name: 'Water', price: 125, quantity: 2 }
  ].freeze

  def initialize_vending_machine
    items = set_initial_items
    balance = set_initial_balance
    VendingMachine.new(items, balance)
  end

  private

  def set_initial_items
    INITIAL_ITEMS.map do |item_data|
      Item.new(item_data[:name], item_data[:price], item_data[:quantity])
    end
  end

  def set_initial_balance
    Change.new(INITIAL_BALANCE)
  end
end
