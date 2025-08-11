
describe ChangeCalculator do
  let(:calculator) { ChangeCalculator.new }

  describe '#can_make_exact_change?' do
    context 'when exact change can be made' do
      let(:balance) do
        {
          200 => 2,  # €2 x 2 = €4.00
          100 => 3,  # €1 x 3 = €3.00
          50 => 4,   # 50c x 4 = €2.00
          20 => 5,   # 20c x 5 = €1.00
          10 => 10,  # 10c x 10 = €1.00
          5 => 20,   # 5c x 20 = €1.00
          2 => 50,   # 2c x 50 = €1.00
          1 => 100   # 1c x 100 = €1.00
        }
      end

      it 'returns true for amount requiring multiple denominations' do
        amount_needed = 73 # 73c = 50c + 20c + 2c + 1c
        expect(calculator.can_make_exact_change?(balance, amount_needed)).to be true
      end

      it 'returns true for amount requiring single denomination' do
        amount_needed = 100 # €1.00 (exact €1 coin)
        expect(calculator.can_make_exact_change?(balance, amount_needed)).to be true
      end

      it 'returns true when amount is zero' do
        amount_needed = 0
        expect(calculator.can_make_exact_change?(balance, amount_needed)).to be true
      end
    end

    context 'when exact change cannot be made' do
      let(:limited_balance) do
        {
          200 => 1,  # €2 x 1 = €2.00
          100 => 0,  # No €1 coins
          50 => 1,   # 50c x 1 = 50c
          20 => 0,   # No 20c coins
          10 => 0,   # No 10c coins
          5 => 0,    # No 5c coins
          2 => 0,    # No 2c coins
          1 => 0     # No 1c coins
        }
      end

      it 'returns false when requiring unavailable small denominations' do
        amount_needed = 73 # 73c needs smaller denominations not available
        expect(calculator.can_make_exact_change?(limited_balance, amount_needed)).to be false
      end

      it 'returns false when total available is less than needed' do
        amount_needed = 300 # €3.00 but only €2.50 available
        expect(calculator.can_make_exact_change?(limited_balance, amount_needed)).to be false
      end
    end

    context 'with empty balance' do
      let(:empty_balance) { {} }

      it 'returns true when no change needed' do
        amount_needed = 0
        expect(calculator.can_make_exact_change?(empty_balance, amount_needed)).to be true
      end
    end
  end

  describe '#make_change' do
    it 'returns empty change for zero amount needed' do
      balance = { 100 => 2, 50 => 1 }
      change_given, new_balance = calculator.make_change(balance, 0)

      expect(change_given).to eq({})
      expect(new_balance).to eq(balance)
    end

    it 'uses greedy algorithm(choosing the largest denomination first) with multiple denominations' do
      balance = { 200 => 2, 100 => 3, 50 => 4, 20 => 5, 10 => 10, 5 => 20, 2 => 50, 1 => 100 }
      change_given, new_balance = calculator.make_change(balance, 73)

      # 73c = 50c + 20c + 2c + 1c (greedy solution)
      expect(change_given).to eq({ 50 => 1, 20 => 1, 2 => 1, 1 => 1 })
      expect(new_balance[50]).to eq(3)
      expect(new_balance[20]).to eq(4)
      expect(new_balance[2]).to eq(49)
      expect(new_balance[1]).to eq(99)
    end

    it 'returns nil when exact change cannot be made' do
      limited_balance = { 200 => 1, 50 => 1 }
      change_given, new_balance = calculator.make_change(limited_balance, 73)

      expect(change_given).to be_nil
      expect(new_balance).to eq(limited_balance)
    end

    it 'handles empty balance' do
      change_given, new_balance = calculator.make_change({}, 50)

      expect(change_given).to be_nil
      expect(new_balance).to eq({})
    end
  end
end
