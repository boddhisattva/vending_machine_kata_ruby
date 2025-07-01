require 'money'

class Change
  ACCEPTABLE_COINS = [
    Money.new(1, 'GBP'),    # 1p
    Money.new(2, 'GBP'),    # 2p
    Money.new(5, 'GBP'),    # 5p
    Money.new(10, 'GBP'),   # 10p
    Money.new(20, 'GBP'),   # 20p
    Money.new(50, 'GBP'),   # 50p
    Money.new(100, 'GBP'),  # £1
    Money.new(200, 'GBP')   # £2
  ].freeze

  def initialize(amount)
    @amount = amount.is_a?(Money) ? amount : Money.new(amount, 'GBP')
  end

  attr_reader :amount
end
