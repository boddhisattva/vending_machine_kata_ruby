require 'money'

# 1072 --> 50 * 10 + 10 * 10 + 20  * 10 + 2 * 100 + 5* 10 + 2 * 10 + 1 * 2

class Change
  DEFAULT_CURRENCY = 'GBP'

  ACCEPTABLE_COINS = [50, 10, 20, 100, 200, 5, 2, 1].freeze

  def initialize(amount)
    unless coins_in_acceptable_denominations?(amount)
      raise ArgumentError, "Please make sure coins are in acceptable denominations: #{ACCEPTABLE_COINS}"
    end

    @amount = amount
  end

  attr_reader :amount

  private

  def coins_in_acceptable_denominations?(amount)
    amount.keys.all? { |coin_denomination| ACCEPTABLE_COINS.include?(coin_denomination) }
  end
end
