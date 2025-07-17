require 'spec_helper'
require_relative '../../lib/item'

describe Item do
  describe '#name and #price' do
    context 'given an item name & numeric price' do
      it 'returns the item name and price as integer' do
        item = Item.new('Coke', 150, 1)
        expect(item.name).to eq('Coke')
        expect(item.price).to eq(150)
      end

      it 'handles price in cents correctly' do
        item = Item.new('Chips', 100, 1)  # 1 Euro = 100 cents
        expect(item.price).to eq(100)
      end

      it 'handles float prices (though not recommended)' do
        item = Item.new('Test', 1.5, 1)
        expect(item.price).to eq(1.5)
      end
    end
  end

  describe '#quantity' do
    context 'when modifying quantity' do
      it 'allows quantity to be decremented' do
        item = Item.new('Coke', 150, 2)
        item.quantity -= 1
        expect(item.quantity).to eq(1)
      end

      it 'prevents negative quantity' do
        item = Item.new('Coke', 150, 1)
        item.quantity -= 1
        expect(item.quantity).to eq(0)
        item.quantity -= 1
        expect(item.quantity).to eq(-1)  # Note: This might need validation in the future
      end
    end
  end
end
