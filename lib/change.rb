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
    return 'No coins' if no_coins?

    coin_descriptions = build_coin_descriptions
    coin_descriptions.empty? ? 'No coins' : coin_descriptions.join(', ')
  end

  def to_euros
    total_cents = calculate_total_amount
    euros = total_cents.to_f / 100.0
    euros.round(2)
  end

  def format_for_return
    return '' if no_coins?

    formatted_coins = build_return_format_descriptions
    formatted_coins.join(', ')
  end

  private

  def no_coins?
    amount.empty?
  end

  def build_coin_descriptions
    sorted_coins_by_denomination
      .filter_map { |denomination, quantity| format_coin_description(denomination, quantity) }
  end

  def sorted_coins_by_denomination
    amount.sort_by { |denomination, _| -denomination }
  end

  def format_coin_description(denomination, quantity)
    display_quantity = prepare_display_quantity(quantity)
    return nil if display_quantity == 0

    coin_name = coin_name_for_denomination(denomination)
    pluralized_description(display_quantity, coin_name)
  end

  def prepare_display_quantity(quantity)
    quantity.to_i
  end

  def pluralized_description(quantity, coin_name)
    if quantity == 1
      "1 #{coin_name}"
    else
      "#{quantity} #{pluralize_coin_name(coin_name)}"
    end
  end

  def pluralize_coin_name(coin_name)
    coin_name.end_with?('y') ? coin_name.sub(/y$/, 'ies') : coin_name + 's'
  end

  def build_return_format_descriptions
    sorted_coins_by_denomination
      .filter_map { |denomination, count| format_return_coin(denomination, count) }
  end

  def format_return_coin(denomination, count)
    return nil if count <= 0

    formatted_denomination = format_denomination_for_return(denomination)
    "#{count} x #{formatted_denomination}"
  end

  def format_denomination_for_return(denomination)
    euro_denomination?(denomination) ? format_as_euros(denomination) : format_as_cents(denomination)
  end

  def euro_denomination?(denomination)
    denomination >= 100
  end

  def format_as_euros(denomination)
    euro_value = denomination / 100
    "€#{euro_value}"
  end

  def format_as_cents(denomination)
    "#{denomination}c"
  end

  def coins_in_acceptable_denominations?(amount)
    amount.keys.all? { |coin_denomination| ACCEPTABLE_COINS.include?(coin_denomination) }
  end

  def coin_name_for_denomination(denomination)
    case denomination
    when 1 then '1-cent coin'
    when 2 then '2-cent coin'
    when 5 then '5-cent coin'
    when 10 then '10-cent coin'
    when 20 then '20-cent coin'
    when 50 then '50-cent coin'
    when 100 then '1 Euro coin'
    when 200 then '2 Euro coin'
    else 'coin'
    end
  end
end
