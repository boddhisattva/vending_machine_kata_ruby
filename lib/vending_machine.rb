class VendingMachine
  def initialize(items, balance)
    @items = items
    @balance = balance
  end

  attr_reader :items, :balance
end
