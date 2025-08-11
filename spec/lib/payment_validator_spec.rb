
describe PaymentValidator do
  let(:validator) { PaymentValidator.new }
  let(:item) { Item.new('Coke', 150, 1) }
  let(:balance) { Change.new({ 50 => 1, 10 => 1 }) }

  describe '#validate_purchase' do
    context 'when item is not available' do
      let(:unavailable_item) { Item.new('Coke', 150, 0) }

      it 'returns error message and balance' do
        result = validator.validate_purchase(unavailable_item, { 200 => 1 }, balance)
        expect(result).to eq(['Item not available', balance])
      end
    end

    context 'when payment has invalid denominations' do
      it 'returns error message for invalid denominations' do
        result = validator.validate_purchase(item, { 25 => 1 }, balance)
        expect(result).to eq(['Invalid coin denomination in payment: [25]', balance])
      end

      it 'returns error message for multiple invalid denominations' do
        result = validator.validate_purchase(item, { 25 => 1, 75 => 1 }, balance)
        expect(result).to eq(['Invalid coin denomination in payment: [25, 75]', balance])
      end
    end

    context 'when item is available and payment is valid' do
      it 'returns nil for successful validation' do
        result = validator.validate_purchase(item, { 200 => 1 }, balance)
        expect(result).to be_nil
      end
    end
  end

  describe '#validate_payment_amount' do
    context 'when payment is insufficient' do
      it 'returns error message for insufficient payment' do
        result = validator.validate_payment_amount(item, 100, balance)
        expect(result).to eq(['You need to pay 50 more cents to purchase Coke', balance])
      end
    end

    context 'when payment is sufficient' do
      it 'returns nil for sufficient payment' do
        result = validator.validate_payment_amount(item, 200, balance)
        expect(result).to be_nil
      end

      it 'returns nil for exact payment' do
        result = validator.validate_payment_amount(item, 150, balance)
        expect(result).to be_nil
      end
    end
  end
end
