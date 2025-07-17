require 'securerandom'
require_relative 'payment_session'

class SingleUserSessionManager < SessionManager
  def initialize
    @current_session = nil
  end

  def start_session(item)
    @current_session = PaymentSession.new(item)
    {
      success: true,
      message: "Please insert #{item.price} cents for #{item.name}",
      session_id: @current_session.id
    }
  end

  def add_payment(session_id, payment)
    return { success: false, message: "No active session" } unless @current_session&.id == session_id

    remaining = @current_session.add_payment(payment)

    if @current_session.sufficient_funds?
      {
        success: true,
        message: "Payment complete",
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
    return { success: false, message: "No active session" } unless @current_session&.id == session_id
    return { success: false, message: "Insufficient funds" } unless @current_session.sufficient_funds?

    session = @current_session
    @current_session = nil  # Clear the session

    {
      success: true,
      message: "Transaction completed successfully",
      session: session
    }
  end

  def cancel_session(session_id)
    return { success: false, message: "No active session" } unless @current_session&.id == session_id

    partial_payment = @current_session.accumulated_payment.dup
    @current_session = nil  # Clear the session

    {
      success: true,
      message: "Session cancelled. Returning partial payment.",
      partial_payment: partial_payment
    }
  end

  def current_session
    @current_session
  end
end
