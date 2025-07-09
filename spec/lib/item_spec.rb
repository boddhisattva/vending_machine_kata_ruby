describe Item do
  describe '#name and #price' do
    context 'given an item name & numeric price' do
      it 'returns the item name and price as integer' do
        item = Item.new('Coke', 1072, 5)
        expect(item.name).to eq('Coke')
        expect(item.price).to eq(1072)
        expect(item.quantity).to eq(5)
      end
    end
  end
end
