class SessionManager
  def start_session(item)
    # Returns { success: true, message: "initial message", session_id: "id" }
    # or { success: false, message: "error message" }
    raise NotImplementedError, 'Subclasses must implement start_session'
  end

  def add_payment(session_id, payment)
    # Returns { success: true, message: "message", completed: true/false, remaining: amount }
    # or { success: false, message: "error message" }
    raise NotImplementedError, 'Subclasses must implement add_payment'
  end

  def complete_session(session_id)
    # Returns { success: true, message: "success message", session: PaymentSession }
    # or { success: false, message: "error message" }
    raise NotImplementedError, 'Subclasses must implement complete_session'
  end

  def cancel_session(session_id)
    # Returns { success: true, message: "cancelled", partial_payment: payment_hash }
    # or { success: false, message: "error message" }
    raise NotImplementedError, 'Subclasses must implement cancel_session'
  end
end
