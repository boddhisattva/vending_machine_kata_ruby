# frozen_string_literal: true

require_relative 'change'

# Handles change calculation logic
class ChangeCalculator
  # Returns [change_given_hash, new_balance_hash] or [nil, original_balance] if cannot make change
  def make_change(balance, change_amount)
    return [{}, balance] if change_amount == 0

    result = calculate_optimal_change(balance.dup, change_amount)

    if change_was_successful?(result[:remaining])
      prepare_successful_result(result[:change_given], result[:new_balance])
    else
      prepare_failure_result(balance)
    end
  end

  def can_make_exact_change?(balance, amount_needed)
    change_given, = make_change(balance.dup, amount_needed)
    !change_given.nil?
  end

  private

  # Uses greedy algorithm to calculate optimal change
  def calculate_optimal_change(balance, amount)
    remaining = amount
    change_given = {}

    sorted_denominations.each do |denomination|
      next if remaining <= 0

      coins_used = calculate_coins_for_denomination(
        denomination,
        remaining,
        balance
      )

      next unless coins_used > 0

      apply_coin_usage(
        denomination,
        coins_used,
        change_given,
        balance
      )
      remaining = update_remaining_amount(remaining, denomination, coins_used)
    end

    { remaining: remaining, change_given: change_given, new_balance: balance }
  end

  # Returns denominations sorted from largest to smallest for greedy algorithm
  def sorted_denominations
    Change::ACCEPTABLE_COINS.sort.reverse
  end

  # Calculates how many coins of a denomination to use
  def calculate_coins_for_denomination(denomination, remaining_amount, available_balance)
    available_coins = available_balance[denomination] || 0
    needed_coins = remaining_amount.div(denomination)
    [available_coins, needed_coins].min
  end

  # Updates the change_given and balance for coins used
  def apply_coin_usage(denomination, coins_used, change_given, balance)
    change_given[denomination] = coins_used
    balance[denomination] -= coins_used
  end

  # Calculates new remaining amount after using coins
  def update_remaining_amount(current_remaining, denomination, coins_used)
    current_remaining - (denomination * coins_used)
  end

  # Checks if exact change was made
  def change_was_successful?(remaining)
    remaining == 0
  end

  # Prepares the success result with cleaned balance
  def prepare_successful_result(change_given, new_balance)
    cleaned_balance = remove_zero_quantity_coins(new_balance)
    [change_given, cleaned_balance]
  end

  # Removes coins with zero quantity from balance
  def remove_zero_quantity_coins(balance)
    balance.reject { |_, qty| qty <= 0 }
  end

  # Prepares the failure result
  def prepare_failure_result(original_balance)
    [nil, original_balance]
  end
end
