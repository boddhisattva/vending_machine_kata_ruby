require 'spec_helper'
# TODO: come back and check for the need to clean up some duplicate specs
# and for some specs let's use mocks else we might be testing the whole thing
# which might already be tested in other payment validator specs
describe PaymentProcessor do
  before do
    @validator = PaymentValidator.new
    @processor = PaymentProcessor.new(@validator)
  end

  describe '#process_payment' do
    before do
      @item = Item.new('Coke', 150, 2)
      @balance = Change.new({ 50 => 6, 10 => 10, 20 => 10, 100 => 2, 200 => 1, 5 => 10, 2 => 10, 1 => 2 })
    end

    it 'processes a successful purchase with change' do
      result, updated_balance = @processor.process_payment(@item, { 200 => 1 }, [@item], @balance)
      expect(result).to eq('Thank you for your purchase of Coke. Please collect your item and change: 50')
      expect(updated_balance.calculate_total_amount).to eq(@balance.calculate_total_amount + 200 - 50)
      expect(@item.quantity).to eq(1)
    end

    it 'processes a successful purchase with exact amount' do
      result, updated_balance = @processor.process_payment(@item, { 100 => 1, 50 => 1 }, [@item], @balance)
      expect(result).to eq('Thank you for your purchase of Coke. Please collect your item.')
      expect(updated_balance.calculate_total_amount).to eq(@balance.calculate_total_amount + 150)
      expect(@item.quantity).to eq(1)
    end

    it 'returns error for insufficient payment' do
      result, updated_balance = @processor.process_payment(@item, { 100 => 1 }, [@item], @balance)
      expect(result).to eq('You need to pay 50 more cents to purchase Coke')
      expect(updated_balance).to eq(@balance)
      expect(@item.quantity).to eq(2)
    end

    it 'returns error for invalid coin denominations' do
      result, updated_balance = @processor.process_payment(@item, { 25 => 1 }, [@item], @balance)
      expect(result).to eq('Invalid coin denomination in payment: [25]')
      expect(updated_balance).to eq(@balance)
      expect(@item.quantity).to eq(2)
    end

    it 'returns error for multiple invalid denominations' do
      result, updated_balance = @processor.process_payment(@item, { 25 => 1, 75 => 1 }, [@item], @balance)
      expect(result).to eq('Invalid coin denomination in payment: [25, 75]')
      expect(updated_balance).to eq(@balance)
      expect(@item.quantity).to eq(2)
    end

    it 'returns error for mixed valid and invalid denominations' do
      result, updated_balance = @processor.process_payment(@item, { 100 => 1, 25 => 1 }, [@item], @balance)
      expect(result).to eq('Invalid coin denomination in payment: [25]')
      expect(updated_balance).to eq(@balance)
      expect(@item.quantity).to eq(2)
    end

    it 'returns error if item is not available' do
      unavailable_item = Item.new('Coke', 150, 0)
      result, updated_balance = @processor.process_payment(unavailable_item, { 200 => 1 }, [unavailable_item], @balance)
      expect(result).to eq('Item not available')
      expect(updated_balance).to eq(@balance)
      expect(unavailable_item.quantity).to eq(0)
    end

    it 'decrements item quantity after successful purchase' do
      @processor.process_payment(@item, { 200 => 1 }, [@item], @balance)
      expect(@item.quantity).to eq(1)
    end

    it 'does not decrement item quantity on failed purchase' do
      @processor.process_payment(@item, { 100 => 1 }, [@item], @balance)
      expect(@item.quantity).to eq(2)
    end
  end
end
