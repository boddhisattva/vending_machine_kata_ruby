describe SessionManager do
  before do
    @manager = SessionManager.new
    @item = Item.new('Coke', 150, 1)
  end

  it 'starts a session and returns correct info' do
    result = @manager.start_session(@item)
    expect(result[:success]).to be true
    expect(result[:message]).to include('Please insert €1.50')
    expect(result[:session_id]).not_to be_nil
  end

  it 'accumulates payments and completes session' do
    result = @manager.start_session(@item)
    session_id = result[:session_id]
    pay1 = @manager.add_payment(session_id, { 100 => 1 })
    expect(pay1[:completed]).to be false
    expect(pay1[:remaining]).to eq(50)
    pay2 = @manager.add_payment(session_id, { 50 => 1 })
    expect(pay2[:completed]).to be true
    expect(pay2[:remaining]).to eq(0)
  end

  it 'handles overpayment and returns completed' do
    result = @manager.start_session(@item)
    session_id = result[:session_id]
    pay = @manager.add_payment(session_id, { 200 => 1 })
    expect(pay[:completed]).to be true
    expect(pay[:remaining]).to eq(0)
  end

  it 'returns error for wrong session id' do
    result = @manager.add_payment('wrong_id', { 100 => 1 })
    expect(result[:success]).to be false
    expect(result[:message]).to eq('No active session')
  end

  it 'formats price in cents for items under 100 cents' do
    cheap_item = Item.new('Gum', 75, 1)
    result = @manager.start_session(cheap_item)
    expect(result[:success]).to be true
    expect(result[:message]).to include('Please insert 75 cents')
    expect(result[:message]).to include('for Gum')
  end
end