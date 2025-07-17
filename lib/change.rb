require 'money'

# 1072 --> 50 * 10 + 10 * 10 + 20  * 10 + 2 * 100 + 5* 10 + 2 * 10 + 1 * 2

class Change
  DEFAULT_CURRENCY = 'EUR'

  ACCEPTABLE_COINS = [50, 10, 20, 100, 200, 5, 2, 1].freeze

  def initialize(amount)
    unless coins_in_acceptable_denominations?(amount)
      raise ArgumentError, "Please make sure coins are in acceptable denominations: #{ACCEPTABLE_COINS}"
    end

    @amount = amount
  end

  attr_reader :amount

  def calculate_total_amount
    amount.sum { |coin_denomination, quantity| coin_denomination * quantity }
  end

  def to_english
    return 'No coins' if amount.empty?

    parts = []
    # Sort by denomination (largest first) for better readability
    sorted_amount = amount.sort_by { |denom, _| -denom }

    sorted_amount.each do |denomination, quantity|
      next if quantity == 0

      # Round to integer for display to avoid floating-point precision issues
      display_quantity = quantity.to_i
      next if display_quantity == 0

      coin_name = coin_name_for_denomination(denomination)
      if display_quantity == 1
        parts << "1 #{coin_name}"
      else
        # Simple pluralization: add 's' for plural
        plural_name = coin_name.end_with?('y') ? coin_name.sub(/y$/, 'ies') : coin_name + 's'
        parts << "#{display_quantity} #{plural_name}"
      end
    end

    parts.empty? ? 'No coins' : parts.join(', ')
  end

  def to_dollars
    total_cents = calculate_total_amount
    dollars = total_cents.to_f / 100.0
    dollars.round(2)
  end

  private

  def coins_in_acceptable_denominations?(amount)
    amount.keys.all? { |coin_denomination| ACCEPTABLE_COINS.include?(coin_denomination) }
  end

  def coin_name_for_denomination(denomination)
    case denomination
    when 1 then 'penny'
    when 2 then '2-cent coin'
    when 5 then 'nickel'
    when 10 then 'dime'
    when 20 then '20-cent coin'
    when 50 then 'half-dollar'
    when 100 then 'dollar coin'
    when 200 then '2-dollar coin'
    else 'coin'
    end
  end
end
