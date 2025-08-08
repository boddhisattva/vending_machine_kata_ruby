require 'spec_helper'

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

      it 'returns true for amount requiring largest denomination' do
        amount_needed = 200 # €2.00 (exact €2 coin)
        expect(calculator.can_make_exact_change?(balance, amount_needed)).to be true
      end

      it 'returns true for complex amount using many coins' do
        amount_needed = 387 # €3.87 = €2 + €1 + 50c + 20c + 10c + 5c + 2c
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

      it 'returns false when denomination gap prevents exact change' do
        amount_needed = 70 # 70c but only have 50c coin, no way to make 20c
        expect(calculator.can_make_exact_change?(limited_balance, amount_needed)).to be false
      end
    end

    context 'with empty balance' do
      let(:empty_balance) { {} }

      it 'returns true when no change needed' do
        amount_needed = 0
        expect(calculator.can_make_exact_change?(empty_balance, amount_needed)).to be true
      end

      it 'returns false when change is needed' do
        amount_needed = 50
        expect(calculator.can_make_exact_change?(empty_balance, amount_needed)).to be false
      end
    end

    context 'edge cases with specific denomination combinations' do
      let(:specific_balance) do
        {
          50 => 3,   # 50c x 3 = €1.50
          20 => 2,   # 20c x 2 = 40c
          10 => 1,   # 10c x 1 = 10c
          5 => 1,    # 5c x 1 = 5c
          2 => 2,    # 2c x 2 = 4c
          1 => 3     # 1c x 3 = 3c
        }
      end

      it 'handles greedy algorithm correctly for tricky amounts' do
        amount_needed = 60 # 60c = 50c + 10c (not 50c + 5c + 2c + 2c + 1c)
        expect(calculator.can_make_exact_change?(specific_balance, amount_needed)).to be true
      end

      it 'correctly uses smaller denominations when larger ones are insufficient' do
        amount_needed = 40 # 40c = 20c + 20c
        expect(calculator.can_make_exact_change?(specific_balance, amount_needed)).to be true
      end

      it 'works when requiring all available small coins' do
        amount_needed = 15 # 15c = 10c + 5c
        expect(calculator.can_make_exact_change?(specific_balance, amount_needed)).to be true
      end
    end

    context 'does not modify original balance' do
      let(:balance) do
        {
          100 => 2,
          50 => 1,
          10 => 5
        }
      end

      it 'preserves original balance after calculation' do
        original_balance = balance.dup
        calculator.can_make_exact_change?(balance, 160)
        expect(balance).to eq(original_balance)
      end
    end
  end

  describe '#make_change' do
    let(:calculator) { ChangeCalculator.new }

    context 'when no change is needed' do
      it 'returns empty change and original balance for zero amount' do
        balance = { 100 => 2, 50 => 1 }
        change_given, new_balance = calculator.make_change(balance, 0)

        expect(change_given).to eq({})
        expect(new_balance).to eq(balance)
      end
    end

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

      it 'makes change using single denomination' do
        change_given, new_balance = calculator.make_change(balance, 100)

        expect(change_given).to eq({ 100 => 1 })
        expect(new_balance[100]).to eq(2) # 3 - 1 = 2
      end

      it 'makes change using multiple denominations optimally' do
        change_given, new_balance = calculator.make_change(balance, 73)

        # 73c = 50c + 20c + 2c + 1c (optimal greedy solution)
        expect(change_given).to eq({ 50 => 1, 20 => 1, 2 => 1, 1 => 1 })
        expect(new_balance[50]).to eq(3)  # 4 - 1 = 3
        expect(new_balance[20]).to eq(4)  # 5 - 1 = 4
        expect(new_balance[2]).to eq(49)  # 50 - 1 = 49
        expect(new_balance[1]).to eq(99)  # 100 - 1 = 99
      end

      it 'uses largest denominations first (greedy algorithm)' do
        change_given, new_balance = calculator.make_change(balance, 350)

        # 350c = €2 + €1 + 50c (using largest denominations first)
        expect(change_given).to eq({ 200 => 1, 100 => 1, 50 => 1 })
        expect(new_balance[200]).to eq(1)  # 2 - 1 = 1
        expect(new_balance[100]).to eq(2)  # 3 - 1 = 2
        expect(new_balance[50]).to eq(3)   # 4 - 1 = 3
      end

      it 'uses all available coins to make exact change' do
        small_balance = { 100 => 1, 50 => 1 }
        change_given, new_balance = calculator.make_change(small_balance, 150)

        expect(change_given).to eq({ 100 => 1, 50 => 1 })
        expect(new_balance).to eq({})
      end

      it 'handles complex change calculations' do
        change_given, new_balance = calculator.make_change(balance, 387)

        # 387c = €2 + €1 + 50c + 20c + 10c + 5c + 2c
        expect(change_given).to eq({
                                     200 => 1, 100 => 1, 50 => 1, 20 => 1, 10 => 1, 5 => 1, 2 => 1
                                   })
        expect(new_balance[200]).to eq(1)  # 2 - 1 = 1
        expect(new_balance[100]).to eq(2)  # 3 - 1 = 2
        expect(new_balance[50]).to eq(3)   # 4 - 1 = 3
      end
    end

    context 'when exact change cannot be made' do
      let(:limited_balance) do
        {
          200 => 1,  # €2 x 1 = €2.00
          50 => 1    # 50c x 1 = 50c
        }
      end

      it 'returns nil change and original balance when insufficient denominations' do
        change_given, new_balance = calculator.make_change(limited_balance, 73)

        expect(change_given).to be_nil
        expect(new_balance).to eq(limited_balance)
      end

      it 'returns nil when total available is less than needed' do
        change_given, new_balance = calculator.make_change(limited_balance, 300)

        expect(change_given).to be_nil
        expect(new_balance).to eq(limited_balance)
      end

      it 'returns nil when denomination gap prevents exact change' do
        change_given, new_balance = calculator.make_change(limited_balance, 70)

        expect(change_given).to be_nil
        expect(new_balance).to eq(limited_balance)
      end
    end

    context 'edge cases' do
      it 'handles empty balance gracefully' do
        change_given, new_balance = calculator.make_change({}, 50)

        expect(change_given).to be_nil
        expect(new_balance).to eq({})
      end

      it 'uses all available coins of a denomination when needed' do
        balance = { 20 => 3, 10 => 1 } # 60c + 10c = 70c total
        change_given, new_balance = calculator.make_change(balance, 60)

        expect(change_given).to eq({ 20 => 3 })
        expect(new_balance).to eq({ 10 => 1 }) # Only 10c coin left
      end

      it 'falls back to smaller denominations when larger ones are insufficient' do
        balance = { 50 => 1, 20 => 2, 10 => 1 }
        change_given, new_balance = calculator.make_change(balance, 40)

        # Can't use 50c (too big), so use 20c + 20c
        expect(change_given).to eq({ 20 => 2 })
        expect(new_balance).to eq({ 50 => 1, 10 => 1 })
      end
    end

    context 'does not modify original balance during calculation' do
      let(:balance) do
        {
          100 => 2,
          50 => 1,
          10 => 5
        }
      end

      it 'preserves original balance hash when change can be made' do
        original_balance = balance.dup
        calculator.make_change(balance, 60)
        expect(balance).to eq(original_balance)
      end

      it 'preserves original balance hash when change cannot be made' do
        original_balance = balance.dup
        calculator.make_change(balance, 1000)
        expect(balance).to eq(original_balance)
      end
    end
  end
end
