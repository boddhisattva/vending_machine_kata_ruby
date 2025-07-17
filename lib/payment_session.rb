require 'securerandom'

class PaymentSession
  attr_reader :id, :item, :accumulated_payment, :total_needed

  def initialize(item)
    @id = generate_session_id
    @item = item
    @accumulated_payment = {}
    @total_needed = item.price  # Price is already in cents
  end

  def add_payment(payment)
    # Merge new payment with accumulated payment
    payment.each do |denomination, count|
      @accumulated_payment[denomination] ||= 0
      @accumulated_payment[denomination] += count
    end

    calculate_remaining_amount
  end

  def total_paid
    @accumulated_payment.sum { |denomination, count| denomination * count }
  end

  def calculate_remaining_amount
    [@total_needed - total_paid, 0].max
  end

  def sufficient_funds?
    total_paid >= @total_needed
  end

  def get_change_amount
    [total_paid - @total_needed, 0].max
  end

    private

  def generate_session_id
    SecureRandom.uuid
  end
end
