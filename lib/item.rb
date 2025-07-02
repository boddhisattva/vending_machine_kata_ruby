require 'money'

class Item
  def initialize(name, price, quantity)
    @name = name
    @price = price.is_a?(Money) ? price : Money.new(price, 'GBP')
    @quantity = quantity
  end

  attr_reader :name, :price, :quantity
end
