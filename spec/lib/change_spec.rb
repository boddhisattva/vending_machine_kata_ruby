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
        let(:one_euro_coins) { Change.new({ 100 => 2 }) }

        it 'formats €2 coins correctly' do
          expect(two_euro_coins.format_for_return).to eq('3 x €2')
        end

        it 'formats €1 coins correctly' do
          expect(one_euro_coins.format_for_return).to eq('2 x €1')
        end
      end

      context 'with cent coins' do
        let(:fifty_cent_coins) { Change.new({ 50 => 4 }) }
        let(:twenty_cent_coins) { Change.new({ 20 => 5 }) }
        let(:ten_cent_coins) { Change.new({ 10 => 8 }) }
        let(:five_cent_coins) { Change.new({ 5 => 6 }) }
        let(:two_cent_coins) { Change.new({ 2 => 10 }) }
        let(:one_cent_coins) { Change.new({ 1 => 7 }) }

        it 'formats 50c coins correctly' do
          expect(fifty_cent_coins.format_for_return).to eq('4 x 50c')
        end

        it 'formats 20c coins correctly' do
          expect(twenty_cent_coins.format_for_return).to eq('5 x 20c')
        end

        it 'formats 10c coins correctly' do
          expect(ten_cent_coins.format_for_return).to eq('8 x 10c')
        end

        it 'formats 5c coins correctly' do
          expect(five_cent_coins.format_for_return).to eq('6 x 5c')
        end

        it 'formats 2c coins correctly' do
          expect(two_cent_coins.format_for_return).to eq('10 x 2c')
        end

        it 'formats 1c coins correctly' do
          expect(one_cent_coins.format_for_return).to eq('7 x 1c')
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

    context 'with single coin quantities' do
      let(:single_coins) { Change.new({ 200 => 1, 50 => 1, 10 => 1, 1 => 1 }) }

      it 'formats single coins correctly' do
        expect(single_coins.format_for_return).to eq('1 x €2, 1 x 50c, 1 x 10c, 1 x 1c')
      end
    end
  end
end
