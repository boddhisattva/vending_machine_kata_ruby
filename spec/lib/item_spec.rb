describe Item do
  describe '#name' do
    context 'give an item name & price' do
      it 'returns the item name' do
        item = Item.new('Coke', 10.72)
        expect(item.name).to eq('Coke')
        expect(item.price).to eq(10.72)
      end
    end
  end
end
