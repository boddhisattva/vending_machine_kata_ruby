require 'spec_helper'
require_relative '../../lib/payment_session'
require_relative '../../lib/item'

describe PaymentSession do
  before do
    @item = Item.new('Coke', 150, 1)
    @session = PaymentSession.new(@item)
  end

  it 'initializes with correct total needed' do
    expect(@session.total_needed).to eq(150)
    expect(@session.calculate_remaining_amount).to eq(150)
    expect(@session.total_paid).to eq(0)
  end

  it 'accumulates payments and calculates remaining' do
    @session.add_payment({ 100 => 1 })
    expect(@session.calculate_remaining_amount).to eq(50)
    @session.add_payment({ 20 => 2 })
    expect(@session.calculate_remaining_amount).to eq(10)
    @session.add_payment({ 10 => 1 })
    expect(@session.calculate_remaining_amount).to eq(0)
    expect(@session.sufficient_funds?).to be true
  end

  it 'handles overpayment and calculates change' do
    @session.add_payment({ 200 => 1 })
    expect(@session.calculate_remaining_amount).to eq(0)
    expect(@session.get_change_amount).to eq(50)
  end

  it 'handles exact payment' do
    @session.add_payment({ 100 => 1, 50 => 1 })
    expect(@session.calculate_remaining_amount).to eq(0)
    expect(@session.get_change_amount).to eq(0)
  end
end
