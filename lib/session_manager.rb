require 'securerandom'
require_relative 'payment_session'
require_relative 'change'
require_relative 'cli/currency_formatter'

class SessionManager
  def initialize
    @current_session = nil
    @currency_formatter = CurrencyFormatter.new
  end

  def start_session(item)
    @current_session = PaymentSession.new(item)
    price_display = format_price_for_payment_message(item.price)
    {
      success: true,
      message: "Please insert #{price_display} for #{item.name}",
      session_id: @current_session.id
    }
  end

  def add_payment(session_id, payment)
    return { success: false, message: 'No active session' } unless @current_session&.id == session_id

    # Validate coin denominations before adding to session
    validation_result = validate_payment_denominations(payment)
    return validation_result unless validation_result.nil?

    remaining = @current_session.add_payment(payment)

    if @current_session.sufficient_funds?
      {
        success: true,
        message: 'Payment complete',
        completed: true,
        remaining: 0
      }
    else
      {
        success: true,
        message: "Please insert #{remaining} more cents",
        completed: false,
        remaining: remaining
      }
    end
  end

  def complete_session(session_id)
    return { success: false, message: 'No active session' } unless @current_session&.id == session_id
    return { success: false, message: 'Insufficient funds' } unless @current_session.sufficient_funds?

    session = @current_session
    @current_session = nil  # Clear the session

    {
      success: true,
      message: 'Transaction completed successfully',
      session: session
    }
  end

  def cancel_session(session_id)
    return { success: false, message: 'No active session' } unless @current_session&.id == session_id

    partial_payment = @current_session.accumulated_payment.dup
    @current_session = nil  # Clear the session

    {
      success: true,
      message: 'Session cancelled. Returning partial payment.',
      partial_payment: partial_payment
    }
  end

  attr_reader :current_session

  private

  def format_price_for_payment_message(price_in_cents)
    if price_in_cents >= 100
      @currency_formatter.format_amount(price_in_cents)
    else
      "#{price_in_cents} cents"
    end
  end

  def validate_payment_denominations(payment)
    invalid_denominations = payment.keys - Change::ACCEPTABLE_COINS
    return unless invalid_denominations.any?

    {
      success: false,
      message: "Invalid coin denomination in payment: #{invalid_denominations}",
      completed: false
    }
  end
end