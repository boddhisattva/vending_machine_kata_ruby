describe Item do
  describe '#name' do
    context 'give an item name' do
      it 'returns the item name' do
        item = Item.new('Coke')
        expect(item.name).to eq('Coke')
      end
    end
  end
end
