require 'spec_helper'
require_relative '../../lib/single_user_session_manager'
require_relative '../../lib/payment_session'
require_relative '../../lib/item'

describe SingleUserSessionManager do
  before do
    @manager = SingleUserSessionManager.new
    @item = Item.new('Coke', 150, 1)
  end

  it 'starts a session and returns correct info' do
    result = @manager.start_session(@item)
    expect(result[:success]).to be true
    expect(result[:message]).to include('Please insert 150 cents')
    expect(result[:session_id]).not_to be_nil
  end

  it 'accumulates payments and completes session' do
    result = @manager.start_session(@item)
    session_id = result[:session_id]
    pay1 = @manager.add_payment(session_id, {100 => 1})
    expect(pay1[:completed]).to be false
    expect(pay1[:remaining]).to eq(50)
    pay2 = @manager.add_payment(session_id, {50 => 1})
    expect(pay2[:completed]).to be true
    expect(pay2[:remaining]).to eq(0)
  end

  it 'handles overpayment and returns completed' do
    result = @manager.start_session(@item)
    session_id = result[:session_id]
    pay = @manager.add_payment(session_id, {200 => 1})
    expect(pay[:completed]).to be true
    expect(pay[:remaining]).to eq(0)
  end

  it 'returns error for wrong session id' do
    result = @manager.add_payment('wrong_id', {100 => 1})
    expect(result[:success]).to be false
    expect(result[:message]).to eq('No active session')
  end
end
