require 'spec_helper'
require_relative '../../lib/reload_manager'
require_relative '../../lib/reload_validator'

describe ReloadManager do
  let(:manager) { ReloadManager.new }
  let(:items) { [Item.new('Coke', 150, 2), Item.new('Chips', 100, 3)] }
  let(:balance) { Change.new({ 100 => 2, 50 => 2 }) }

  describe '#reload_item' do
    context 'reloading existing item' do
      it 'increases quantity and returns success message' do
        result, updated_items = manager.reload_item(items, 'Coke', 5)
        expect(result).to eq('Successfully added 5 units to Coke. New quantity: 7')
        expect(updated_items.first.quantity).to eq(7)
        expect(updated_items).to eq(items) # Same array reference
      end

      it 'ignores price parameter for existing items' do
        result, = manager.reload_item(items, 'Coke', 3, 200)
        expect(result).to eq('Successfully added 3 units to Coke. New quantity: 5')
      end
    end

    context 'adding new item' do
      it 'adds new item with correct attributes' do
        result, updated_items = manager.reload_item(items, 'Water', 10, 125)
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
        result, returned_items = manager.reload_item(items, 'Coke', -5)
        expect(result).to eq('Invalid quantity. Please provide a positive number.')
        expect(returned_items).to eq(items)
        expect(items.first.quantity).to eq(2) # Unchanged
      end

      it 'returns error for missing price on new item' do
        result, returned_items = manager.reload_item(items, 'Water', 5)
        expect(result).to eq('Price required for new item')
        expect(returned_items).to eq(items)
        expect(items.size).to eq(2) # No new item added
      end
    end

    context 'with custom validator' do
      let(:mock_validator) { double('ReloadValidator') }
      let(:manager_with_validator) { ReloadManager.new(mock_validator) }

      it 'uses injected validator' do
        expect(mock_validator).to receive(:validate_item_reload)
          .with(items, 'Coke', 5, nil)
          .and_return(nil)

        manager_with_validator.reload_item(items, 'Coke', 5)
      end
    end
  end

  describe '#reload_change' do
    context 'successful reload' do
      it 'adds coins and returns success message' do
        result, new_balance = manager.reload_change(balance, { 100 => 3, 50 => 2 })
        expect(result).to include('Successfully added coins')
        expect(result).to include('3 1 Euro coins, 2 50-cent coins')
        expect(result).to include('Total balance: €7.00')

        # Verify new balance
        expect(new_balance.amount[100]).to eq(5) # 2 + 3
        expect(new_balance.amount[50]).to eq(4)  # 2 + 2
      end

      it 'handles new denominations not in current balance' do
        result, new_balance = manager.reload_change(balance, { 20 => 5, 5 => 10 })
        expect(result).to include('Successfully added coins')
        expect(new_balance.amount[20]).to eq(5)
        expect(new_balance.amount[5]).to eq(10)
      end

      it 'returns new Change object, not modifying original' do
        original_amount = balance.amount.dup
        _, new_balance = manager.reload_change(balance, { 100 => 1 })

        expect(balance.amount).to eq(original_amount)
        expect(new_balance).not_to eq(balance)
      end
    end

    context 'validation errors' do
      it 'returns error for invalid denomination' do
        result, returned_balance = manager.reload_change(balance, { 25 => 5 })
        expect(result).to eq('Invalid coin denominations: [25]')
        expect(returned_balance).to eq(balance)
      end

      it 'returns error for non-hash input' do
        result, returned_balance = manager.reload_change(balance, 'invalid')
        expect(result).to eq('Invalid input. Please provide a hash of coins.')
        expect(returned_balance).to eq(balance)
      end

      it 'returns error for negative quantity' do
        result, returned_balance = manager.reload_change(balance, { 100 => -5 })
        expect(result).to eq('Invalid input. All quantities must be positive.')
        expect(returned_balance).to eq(balance)
      end
    end

    context 'with custom validator' do
      let(:mock_validator) { double('ReloadValidator') }
      let(:manager_with_validator) { ReloadManager.new(mock_validator) }

      it 'uses injected validator' do
        expect(mock_validator).to receive(:validate_coin_reload)
          .with({ 100 => 5 })
          .and_return(nil)

        manager_with_validator.reload_change(balance, { 100 => 5 })
      end
    end
  end
end
