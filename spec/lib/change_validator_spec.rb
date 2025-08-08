require 'spec_helper'

describe ChangeValidator do
  let(:change_calculator) { instance_double('ChangeCalculator') }
  let(:validator) { ChangeValidator.new(change_calculator) }
  let(:current_balance) { instance_double('Change') }

  describe '#validate_change_availability' do
    let(:balance_amount) do
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

    before do
      allow(current_balance).to receive(:amount).and_return(balance_amount)
    end

    context 'when exact payment is made' do
      let(:payment) { { 100 => 1 } } # €1.00
      let(:item_price) { 100 } # €1.00

      it 'returns nil (no error) since no change is needed' do
        result = validator.validate_change_availability(payment, item_price, current_balance)
        expect(result).to be_nil
      end
    end

    context 'when underpayment occurs' do
      let(:payment) { { 50 => 1 } } # 50c
      let(:item_price) { 100 } # €1.00

      it 'returns nil (no error) since no change is needed' do
        result = validator.validate_change_availability(payment, item_price, current_balance)
        expect(result).to be_nil
      end
    end

    context 'when overpayment occurs and change can be made' do
      let(:payment) { { 200 => 1 } } # €2.00
      let(:item_price) { 150 } # €1.50
      let(:change_needed) { 50 } # 50c change needed

      before do
        expected_balance = balance_amount.dup
        expected_balance[200] = (expected_balance[200] || 0) + 1
        allow(change_calculator).to receive(:can_make_exact_change?)
          .with(expected_balance, change_needed)
          .and_return(true)
      end

      it 'returns nil (no error) since change can be made' do
        result = validator.validate_change_availability(payment, item_price, current_balance)
        expect(result).to be_nil
      end
    end

    context 'when overpayment occurs and change cannot be made' do
      let(:payment) { { 200 => 1 } } # €2.00
      let(:item_price) { 173 } # €1.73
      let(:change_needed) { 27 } # 27c change needed

      before do
        expected_balance = balance_amount.dup
        expected_balance[200] = (expected_balance[200] || 0) + 1
        allow(change_calculator).to receive(:can_make_exact_change?)
          .with(expected_balance, change_needed)
          .and_return(false)
      end

      it 'returns error message about insufficient change' do
        result = validator.validate_change_availability(payment, item_price, current_balance)
        expect(result).to eq("Cannot provide change with available coins. Please type 'cancel' to get refund and to restart purchase attempt with the exact amount")
      end
    end

    context 'with multiple payment coins' do
      let(:payment) do
        {
          100 => 2,  # €1 x 2 = €2.00
          50 => 1,   # 50c x 1 = 50c
          10 => 2    # 10c x 2 = 20c
        }
      end
      let(:item_price) { 200 } # €2.00
      let(:total_payment) { 270 } # €2.70 total payment
      let(:change_needed) { 70 } # 70c change needed

      before do
        expected_balance = balance_amount.dup
        expected_balance[100] = (expected_balance[100] || 0) + 2
        expected_balance[50] = (expected_balance[50] || 0) + 1
        expected_balance[10] = (expected_balance[10] || 0) + 2
        
        allow(change_calculator).to receive(:can_make_exact_change?)
          .with(expected_balance, change_needed)
          .and_return(true)
      end

      it 'correctly calculates change needed and validates availability' do
        result = validator.validate_change_availability(payment, item_price, current_balance)
        expect(result).to be_nil
      end
    end

    context 'when payment includes new denomination not in balance' do
      let(:payment) { { 1 => 50 } } # 1c x 50 = 50c
      let(:item_price) { 30 } # 30c
      let(:change_needed) { 20 } # 20c change needed
      let(:balance_without_cents) do
        {
          200 => 1,
          100 => 1,
          50 => 1
        }
      end

      before do
        allow(current_balance).to receive(:amount).and_return(balance_without_cents)
        expected_balance = balance_without_cents.dup
        expected_balance[1] = 50 # Adding the 1c coins from payment
        
        allow(change_calculator).to receive(:can_make_exact_change?)
          .with(expected_balance, change_needed)
          .and_return(true)
      end

      it 'includes payment coins in balance when checking change availability' do
        result = validator.validate_change_availability(payment, item_price, current_balance)
        expect(result).to be_nil
      end
    end

    context 'with edge case amounts' do
      let(:payment) { { 200 => 1, 100 => 1, 50 => 1, 1 => 1 } } # €3.51
      let(:item_price) { 299 } # €2.99
      let(:change_needed) { 52 } # 52c change needed

      before do
        expected_balance = balance_amount.dup
        expected_balance[200] = (expected_balance[200] || 0) + 1
        expected_balance[100] = (expected_balance[100] || 0) + 1
        expected_balance[50] = (expected_balance[50] || 0) + 1
        expected_balance[1] = (expected_balance[1] || 0) + 1
        
        allow(change_calculator).to receive(:can_make_exact_change?)
          .with(expected_balance, change_needed)
          .and_return(false)
      end

      it 'handles complex payment combinations correctly' do
        result = validator.validate_change_availability(payment, item_price, current_balance)
        expect(result).to eq("Cannot provide change with available coins. Please type 'cancel' to get refund and to restart purchase attempt with the exact amount")
      end
    end

    context 'when balance has zero coins for some denominations' do
      let(:sparse_balance) do
        {
          200 => 0,
          100 => 1,
          50 => 0,
          20 => 2,
          10 => 0,
          5 => 3,
          2 => 0,
          1 => 5
        }
      end
      let(:payment) { { 100 => 2 } } # €2.00
      let(:item_price) { 150 } # €1.50
      let(:change_needed) { 50 } # 50c change needed

      before do
        allow(current_balance).to receive(:amount).and_return(sparse_balance)
        expected_balance = sparse_balance.dup
        expected_balance[100] = 1 + 2 # existing + payment
        
        allow(change_calculator).to receive(:can_make_exact_change?)
          .with(expected_balance, change_needed)
          .and_return(true)
      end

      it 'works with sparse balance having zero values' do
        result = validator.validate_change_availability(payment, item_price, current_balance)
        expect(result).to be_nil
      end
    end
  end

  describe 'initialization' do
    it 'accepts a change calculator dependency' do
      custom_calculator = instance_double('ChangeCalculator')
      validator = ChangeValidator.new(custom_calculator)
      expect(validator.instance_variable_get(:@change_calculator)).to eq(custom_calculator)
    end

    it 'creates a default change calculator when none provided' do
      validator = ChangeValidator.new
      expect(validator.instance_variable_get(:@change_calculator)).to be_a(ChangeCalculator)
    end
  end
end