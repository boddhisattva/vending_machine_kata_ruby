
describe PaymentSession do
  before do
    @item = Item.new('Coke', 150, 1)
    @session = PaymentSession.new(@item)
  end

  it 'initializes with correct total needed' do
    expect(@session.total_needed).to eq(150)
  end

  it 'accumulates payments and calculates remaining' do
    @session.add_payment({ 100 => 1 })
    @session.add_payment({ 20 => 2 })
    @session.add_payment({ 10 => 1 })
    expect(@session.sufficient_funds?).to be true
  end
end
