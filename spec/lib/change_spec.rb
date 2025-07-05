require 'spec_helper'

describe Change do
  let(:balance) { Change.new(balance_coins) }
  let(:balance_coins) do
    {
      50 => 6,
      10 => 10,
      20 => 10,
      100 => 2,
      200 => 1,
      5 => 10,
      2 => 10,
      1 => 2
    }
  end

  describe '#initialize' do
    context 'given a set of coins' do
      it 'returns the total amount' do
        expect(balance.amount).to eq(balance_coins)
      end
    end

    context 'given invalid coin denominations' do
      let(:invalid_coins) do
        {
          50 => 6,
          10 => 10,
          20 => 10,
          100 => 2,
          200 => 1,
          5 => 10,
          2 => 10,
          1 => 2,
          25 => 5 # Invalid denomination
        }
      end

      it 'raises an ArgumentError with appropriate message' do
        expect { Change.new(invalid_coins) }.to raise_error(
          ArgumentError,
          'Please make sure coins are in acceptable denominations: [50, 10, 20, 100, 200, 5, 2, 1]'
        )
      end
    end
  end
  #   it 'contains Money objects for valid UK denominations' do
  #     expected_coins = [
  #       Money.new(1, 'GBP'),    # 1p
  #       Money.new(2, 'GBP'),    # 2p
  #       Money.new(5, 'GBP'),    # 5p
  #       Money.new(10, 'GBP'),   # 10p
  #       Money.new(20, 'GBP'),   # 20p
  #       Money.new(50, 'GBP'),   # 50p
  #       Money.new(100, 'GBP'),  # £1
  #       Money.new(200, 'GBP')   # £2
  #     ]
  #     expect(Change::ACCEPTABLE_COINS).to eq(expected_coins)
  #   end
  # end
end
