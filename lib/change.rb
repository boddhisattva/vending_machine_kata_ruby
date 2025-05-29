class Change
  ACCEPTABLE_COINS = [0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2]

  def initialize(amount)
    @amount = amount
  end

  attr_reader :amount
end
