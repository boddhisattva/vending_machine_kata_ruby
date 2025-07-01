require 'money'

class Item
  def initialize(name, price)
    @name = name
    @price = price.is_a?(Money) ? price : Money.new(price, 'GBP')
  end

  attr_reader :name, :price
end
