require 'spec_helper'

describe Change do
  describe '#amount' do
    context 'given a numeric amount' do
      it 'returns the amount as Money object' do
        change = Change.new(1072)
        expect(change.amount).to be_a(Money)
        expect(change.amount.cents).to eq(1072)
        expect(change.amount.currency.iso_code).to eq('GBP')
      end
    end
  end

  describe 'ACCEPTABLE_COINS' do
    it 'contains Money objects for valid UK denominations' do
      expected_coins = [
        Money.new(1, 'GBP'),    # 1p
        Money.new(2, 'GBP'),    # 2p
        Money.new(5, 'GBP'),    # 5p
        Money.new(10, 'GBP'),   # 10p
        Money.new(20, 'GBP'),   # 20p
        Money.new(50, 'GBP'),   # 50p
        Money.new(100, 'GBP'),  # £1
        Money.new(200, 'GBP')   # £2
      ]
      expect(Change::ACCEPTABLE_COINS).to eq(expected_coins)
    end
  end
end
