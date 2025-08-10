require_relative 'reload_validator'
require_relative 'change'

class ChangeReloader
  def initialize(reload_validator = ReloadValidator.new)
    @reload_validator = reload_validator
  end

  def reload_change(balance, coins_to_add)
    validation_error = @reload_validator.validate_coin_reload(coins_to_add)
    return [validation_error, balance] if validation_error

    new_balance = build_new_balance(balance, coins_to_add)
    message = build_success_message(coins_to_add, new_balance)

    [message, new_balance]
  end

  private

  def build_new_balance(balance, coins_to_add)
    new_balance_hash = balance.amount.dup
    
    coins_to_add.each do |denomination, count|
      new_balance_hash[denomination] ||= 0
      new_balance_hash[denomination] += count
    end

    Change.new(new_balance_hash)
  end

  def build_success_message(coins_to_add, new_balance)
    added_change = Change.new(coins_to_add)
    "Successfully added coins: #{added_change.to_english}. Total balance: €#{'%.2f' % new_balance.to_euros}"
  end
end