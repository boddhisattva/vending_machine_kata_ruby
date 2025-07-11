require 'spec_helper'

describe Item do
  describe '#name and #price' do
    context 'given an item name & numeric price' do
      it 'returns the item name and price as integer' do
        item = Item.new('Coke', 150, 5)
        expect(item.name).to eq('Coke')
        expect(item.price).to eq(150)
        expect(item.quantity).to eq(5)
      end
    end
  end

  describe '#quantity' do
    context 'when modifying quantity' do
      it 'allows quantity to be decremented' do
        item = Item.new('Coke', 150, 5)
        initial_quantity = item.quantity

        item.quantity -= 1

        expect(item.quantity).to eq(initial_quantity - 1)
      end
    end
  end
end
