
describe ItemLoader do
  let(:reloader) { ItemLoader.new }
  let(:items) { [Item.new('Coke', 150, 2), Item.new('Chips', 100, 3)] }
  let(:items_index) { items.each_with_object({}) { |item, hash| hash[item.name] = item } }

  describe '#load_item' do
    context 'reloading existing item' do
      it 'increases quantity and returns success message' do
        result, updated_items = reloader.load_item(items, items_index, 'Coke', 5)
        expect(result).to eq('Successfully added 5 units to Coke. New quantity: 7')
        expect(updated_items.first.quantity).to eq(7)
        expect(updated_items).to eq(items) # Same array reference
      end

      it 'ignores price parameter for existing items' do
        result, = reloader.load_item(items, items_index, 'Coke', 3, 200)
        expect(result).to eq('Successfully added 3 units to Coke. New quantity: 5')
      end
    end

    context 'adding new item' do
      it 'adds new item with correct attributes' do
        result, updated_items = reloader.load_item(items, items_index, 'Water', 10, 125)
        expect(result).to eq('Successfully added new item: Water - €1.25 (10 units)')
        expect(updated_items.size).to eq(3)

        water = updated_items.last
        expect(water.name).to eq('Water')
        expect(water.price).to eq(125)
        expect(water.quantity).to eq(10)
      end
    end

    context 'validation errors' do
      it 'returns error for invalid quantity' do
        result, returned_items = reloader.load_item(items, items_index, 'Coke', -5)
        expect(result).to eq('Invalid quantity. Please provide a positive number.')
        expect(returned_items).to eq(items)
        expect(items.first.quantity).to eq(2) # Unchanged
      end

      it 'returns error for missing price on new item' do
        result, returned_items = reloader.load_item(items, items_index, 'Water', 5)
        expect(result).to eq('Price required for new item')
        expect(returned_items).to eq(items)
        expect(items.size).to eq(2) # No new item added
      end
    end

    context 'with custom validator' do
      let(:mock_validator) { double('ReloadValidator') }
      let(:reloader_with_validator) { ItemLoader.new(mock_validator) }

      it 'uses injected validator' do
        expect(mock_validator).to receive(:validate_item_reload)
          .with(items_index, 'Coke', 5, nil)
          .and_return(nil)

        reloader_with_validator.load_item(items, items_index, 'Coke', 5)
      end
    end
  end
end
