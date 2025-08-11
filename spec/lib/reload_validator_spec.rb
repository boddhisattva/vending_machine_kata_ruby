
describe ReloadValidator do
  let(:validator) { ReloadValidator.new }
  let(:items) { [Item.new('Coke', 150, 2)] }
  let(:items_index) { items.each_with_object({}) { |item, hash| hash[item.name] = item } }

  describe '#validate_item_reload' do
    context 'validating quantity' do
      it 'returns error for non-integer quantity' do
        result = validator.validate_item_reload(items_index, 'Coke', 'five', nil)
        expect(result).to eq('Invalid quantity. Please provide a positive number.')
      end

      it 'returns error for negative quantity' do
        result = validator.validate_item_reload(items_index, 'Coke', -5, nil)
        expect(result).to eq('Invalid quantity. Please provide a positive number.')
      end

      it 'returns error for zero quantity' do
        result = validator.validate_item_reload(items_index, 'Coke', 0, nil)
        expect(result).to eq('Invalid quantity. Please provide a positive number.')
      end

      it 'returns error for float quantity' do
        result = validator.validate_item_reload(items_index, 'Coke', 5.5, nil)
        expect(result).to eq('Invalid quantity. Please provide a positive number.')
      end
    end

    context 'validating new items' do
      it 'returns error when price missing for new item' do
        result = validator.validate_item_reload(items_index, 'Water', 5, nil)
        expect(result).to eq('Price required for new item')
      end

      it 'returns error for non-integer price' do
        result = validator.validate_item_reload(items_index, 'Water', 5, 'one-fifty')
        expect(result).to eq('Invalid price. Price must be positive.')
      end

      it 'returns error for negative price' do
        result = validator.validate_item_reload(items_index, 'Water', 5, -150)
        expect(result).to eq('Invalid price. Price must be positive.')
      end

      it 'returns error for zero price' do
        result = validator.validate_item_reload(items_index, 'Water', 5, 0)
        expect(result).to eq('Invalid price. Price must be positive.')
      end
    end

    context 'successful validation' do
      it 'returns nil for valid existing item reload' do
        result = validator.validate_item_reload(items_index, 'Coke', 10, nil)
        expect(result).to be_nil
      end

      it 'returns nil for valid new item' do
        result = validator.validate_item_reload(items_index, 'Water', 5, 125)
        expect(result).to be_nil
      end

      it 'ignores price when reloading existing item' do
        result = validator.validate_item_reload(items_index, 'Coke', 5, 200)
        expect(result).to be_nil
      end
    end
  end

  describe '#validate_coin_reload' do
    context 'validating input type' do
      it 'returns error for non-hash input' do
        result = validator.validate_coin_reload('invalid')
        expect(result).to eq('Invalid input. Please provide a hash of coins.')
      end

      it 'returns error for array input' do
        result = validator.validate_coin_reload([100, 50])
        expect(result).to eq('Invalid input. Please provide a hash of coins.')
      end

      it 'returns error for nil input' do
        result = validator.validate_coin_reload(nil)
        expect(result).to eq('Invalid input. Please provide a hash of coins.')
      end
    end

    context 'validating quantities' do
      it 'returns error for negative quantity' do
        result = validator.validate_coin_reload({ 100 => -5 })
        expect(result).to eq('Invalid input. All quantities must be positive.')
      end

      it 'returns error for zero quantity' do
        result = validator.validate_coin_reload({ 100 => 0 })
        expect(result).to eq('Invalid input. All quantities must be positive.')
      end

      it 'returns error for non-integer quantity' do
        result = validator.validate_coin_reload({ 100 => 5.5 })
        expect(result).to eq('Invalid input. All quantities must be positive.')
      end

      it 'returns error if any quantity is invalid' do
        result = validator.validate_coin_reload({ 100 => 5, 50 => -1 })
        expect(result).to eq('Invalid input. All quantities must be positive.')
      end
    end

    context 'validating denominations' do
      it 'returns error for invalid denomination' do
        result = validator.validate_coin_reload({ 25 => 5 })
        expect(result).to eq('Invalid coin denominations: [25]')
      end

      it 'returns error for multiple invalid denominations' do
        result = validator.validate_coin_reload({ 25 => 5, 75 => 2 })
        expect(result).to eq('Invalid coin denominations: [25, 75]')
      end

      it 'returns error for mixed valid and invalid' do
        result = validator.validate_coin_reload({ 100 => 5, 25 => 2 })
        expect(result).to eq('Invalid coin denominations: [25]')
      end
    end

    context 'successful validation' do
      it 'returns nil for valid input' do
        result = validator.validate_coin_reload({ 100 => 5, 50 => 10 })
        expect(result).to be_nil
      end

      it 'accepts all valid denominations' do
        valid_coins = { 1 => 5, 2 => 5, 5 => 5, 10 => 5, 20 => 5, 50 => 5, 100 => 5, 200 => 5 }
        result = validator.validate_coin_reload(valid_coins)
        expect(result).to be_nil
      end
    end
  end
end
