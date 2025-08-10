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

  describe '#calculate_total_amount' do
    context 'with multiple currency coins' do
      let(:multiple_currency_coins) { Change.new({ 200 => 4, 50 => 3, 100 => 2 }) }

      it 'calculates multiple 2 euro coins correctly' do
        expect(multiple_currency_coins.calculate_total_amount).to eq(1150)
      end
    end
  end

  describe '#format_for_return' do
    context 'with empty amount' do
      let(:empty_change) { Change.new({}) }

      it 'returns empty string' do
        expect(empty_change.format_for_return).to eq('')
      end
    end

    context 'with single denomination coins' do
      context 'with euro coins' do
        let(:two_euro_coins) { Change.new({ 200 => 3 }) }

        it 'formats €2 coins correctly' do
          expect(two_euro_coins.format_for_return).to eq('3 x €2')
        end
      end

      context 'with cent coins' do
        let(:fifty_cent_coins) { Change.new({ 50 => 4 }) }

        it 'formats 50c coins correctly' do
          expect(fifty_cent_coins.format_for_return).to eq('4 x 50c')
        end
      end
    end

    context 'with multiple denominations' do
      let(:mixed_all) do
        Change.new({
                     200 => 1,
                     100 => 2,
                     50 => 3,
                     20 => 2,
                     10 => 1,
                     5 => 4,
                     2 => 5,
                     1 => 7
                   })
      end

      it 'formats all denominations in descending order' do
        expected = '1 x €2, 2 x €1, 3 x 50c, 2 x 20c, 1 x 10c, 4 x 5c, 5 x 2c, 7 x 1c'
        expect(mixed_all.format_for_return).to eq(expected)
      end
    end

    context 'with zero quantity coins' do
      let(:with_zeros) { Change.new({ 200 => 2, 100 => 0, 50 => 3, 20 => 0, 10 => 1 }) }

      it 'excludes coins with zero quantity' do
        expect(with_zeros.format_for_return).to eq('2 x €2, 3 x 50c, 1 x 10c')
      end
    end
  end

  describe '#to_english' do
    context 'with empty amount' do
      let(:empty_change) { Change.new({}) }

      it 'returns "No coins"' do
        expect(empty_change.to_english).to eq('No coins')
      end
    end

    context 'with single denomination coins' do
      context 'with euro coins' do
        let(:single_two_euro) { Change.new({ 200 => 1 }) }
        let(:multiple_two_euros) { Change.new({ 200 => 3 }) }

        it 'formats single 2 Euro coin correctly' do
          expect(single_two_euro.to_english).to eq('1 2 Euro coin')
        end

        it 'formats multiple 2 Euro coins correctly' do
          expect(multiple_two_euros.to_english).to eq('3 2 Euro coins')
        end
      end

      context 'with cent coins' do
        let(:single_ten_cent) { Change.new({ 10 => 1 }) }
        let(:multiple_one_cents) { Change.new({ 1 => 8 }) }

        it 'formats single 10-cent coin correctly' do
          expect(single_ten_cent.to_english).to eq('1 10-cent coin')
        end

        it 'formats multiple 1-cent coins correctly' do
          expect(multiple_one_cents.to_english).to eq('8 1-cent coins')
        end
      end
    end

    context 'with multiple denominations' do
      let(:mixed_euros_and_cents) do
        Change.new({
                     200 => 2,
                     100 => 1,
                     50 => 3,
                     10 => 2
                   })
      end

      it 'formats mixed euros and cents in descending order' do
        expected = '2 2 Euro coins, 1 1 Euro coin, 3 50-cent coins, 2 10-cent coins'
        expect(mixed_euros_and_cents.to_english).to eq(expected)
      end
    end

    context 'with zero quantity coins' do
      let(:with_zeros) do
        Change.new({
                     200 => 0,
                     100 => 2,
                     50 => 0,
                     10 => 3
                   })
      end

      let(:all_zeros) do
        Change.new({
                     200 => 0,
                     100 => 0,
                     50 => 0
                   })
      end

      it 'excludes coins with zero quantity' do
        expect(with_zeros.to_english).to eq('2 1 Euro coins, 3 10-cent coins')
      end

      it 'returns "No coins" when all quantities are zero' do
        expect(all_zeros.to_english).to eq('No coins')
      end
    end
  end

  describe '#to_euros' do
    context 'with empty amount' do
      let(:empty_change) { Change.new({}) }

      it 'returns 0.0 euros' do
        expect(empty_change.to_euros).to eq(0.0)
      end
    end

    context 'with only cent coins' do
      let(:ninety_nine_cents) { Change.new({ 50 => 1, 20 => 2, 5 => 1, 2 => 2 }) }

      it 'converts 99 cents to 0.99 euros' do
        expect(ninety_nine_cents.to_euros).to eq(0.99)
      end
    end

    context 'with only euro coins' do
      let(:five_euros) { Change.new({ 200 => 2, 100 => 1 }) }
      it 'converts multiple euro coins to correct euro amount' do
        expect(five_euros.to_euros).to eq(5.0)
      end
    end

    context 'with mixed euro and cent coins' do
      let(:mixed_small) { Change.new({ 100 => 1, 50 => 1, 20 => 2, 5 => 1 }) }

      it 'converts €1.95 correctly' do
        expect(mixed_small.to_euros).to eq(1.95)
      end
    end
  end
end
