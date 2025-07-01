describe Item do
  describe '#name and #price' do
    context 'given an item name & numeric price' do
      it 'returns the item name and price as Money object' do
        item = Item.new('Coke', 1072)
        expect(item.name).to eq('Coke')
        expect(item.price).to be_a(Money)
        expect(item.price.cents).to eq(1072)
        expect(item.price.currency.iso_code).to eq('GBP')
      end
    end
  end
end
