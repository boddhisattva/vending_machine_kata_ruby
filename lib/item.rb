class Item
  def initialize(name, price, quantity)
    @name = name
    @price = price
    @quantity = quantity
  end

  attr_reader :name, :price
  attr_accessor :quantity
end
