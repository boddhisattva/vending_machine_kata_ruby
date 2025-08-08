require 'spec_helper'
require_relative '../../lib/payment_processor'
require_relative '../../lib/item'
require_relative '../../lib/change'

describe PaymentProcessor do
  before do
    @processor = PaymentProcessor.new
    @item = Item.new('Coke', 150, 1)
    @balance = Change.new({ 100 => 2, 50 => 1 })
  end

  describe '#process_payment' do
    it 'processes a successful purchase with change' do
      item = Item.new('Coke', 150, 1)
      balance = Change.new({ 100 => 2, 50 => 1 })
      processor = PaymentProcessor.new
      result, = processor.process_payment(item, { 200 => 1 }, [item], balance)
      expect(result).to eq('Thank you for your purchase of Coke. Please collect your item and change: 1 x 50c')
    end

    it 'processes a successful purchase with exact amount' do
      result, = @processor.process_payment(@item, { 100 => 1, 50 => 1 }, [@item], @balance)
      expect(result).to eq('Thank you for your purchase of Coke. Please collect your item.')
    end

    it 'returns error for insufficient payment' do
      result, = @processor.process_payment(@item, { 100 => 1 }, [@item], @balance)
      expect(result).to eq('You need to pay 50 more cents to purchase Coke')
    end

    it 'returns error if item is not available' do
      unavailable_item = Item.new('Coke', 150, 0)
      result, = @processor.process_payment(unavailable_item, { 200 => 1 }, [unavailable_item], @balance)
      expect(result).to eq('Item not available')
    end

    it 'decrements item quantity after successful purchase' do
      item = Item.new('Coke', 150, 2)
      @processor.process_payment(item, { 200 => 1 }, [item], @balance)
      expect(item.quantity).to eq(1)
    end

    it 'does not decrement item quantity on failed purchase' do
      item = Item.new('Coke', 150, 2)
      @processor.process_payment(item, { 100 => 1 }, [item], @balance)
      expect(item.quantity).to eq(2)
    end

    context 'change calculation edge cases' do
      it 'gives optimal change using available denominations' do
        # Machine has 50c and 20c coins, but no 1 Euro coins
        balance = Change.new({ 50 => 2, 20 => 5, 5 => 10 })
        item = Item.new('Chips', 100, 1) # 1 Euro item

        result, = @processor.process_payment(item, { 200 => 1 }, [item], balance)
        expect(result).to eq('Thank you for your purchase of Chips. Please collect your item and change: 2 x 50c')
      end

      it 'handles multiple coin denominations in change' do
        balance = Change.new({ 100 => 1, 50 => 1, 20 => 2, 5 => 1 })
        item = Item.new('Candy', 75, 1) # 75 cents

        result, = @processor.process_payment(item, { 200 => 1 }, [item], balance)
        expect(result).to eq('Thank you for your purchase of Candy. Please collect your item and change: 1 x 100c, 1 x 20c, 1 x 5c')
      end
    end
  end
end
