describe VendingMachine do
  let(:items) { [Item.new('Coke', 150, 1), Item.new('Pepsi', 175, 1)] }
  let(:balance) { Change.new(balance_coins) }
  let(:balance_coins) do
    {
      50 => 6,
      10 => 10,
      20 => 10,
      100 => 2,
      200 => 1,
      5 => 10,
      2 => 10,
      1 => 2
    }
  end

  describe '#initialize' do
    context 'given a set of items & balance' do
      it 'returns the items & balance' do
        vending_machine = VendingMachine.new(items, balance)
        expect(vending_machine.items).to eq(items)
        expect(vending_machine.balance).to eq(balance)
      end
    end
  end

  describe '#load_item' do
    let(:vending_machine) { VendingMachine.new(items, balance) }

    context 'when reloading an existing item' do
      it 'increases the quantity and returns success message' do
        initial_quantity = vending_machine.items.first.quantity
        message = vending_machine.load_item('Coke', 5)

        expect(message).to eq('Successfully added 5 units to Coke. New quantity: 6')
        expect(vending_machine.items.first.quantity).to eq(initial_quantity + 5)
      end

      it 'ignores price parameter for existing items' do
        message = vending_machine.load_item('Coke', 3, 999)

        expect(message).to eq('Successfully added 3 units to Coke. New quantity: 4')
        expect(vending_machine.items.first.price).to eq(150) # Price unchanged
      end

      it 'maintains reference to the same items array' do
        original_items_object_id = vending_machine.items.object_id
        vending_machine.load_item('Coke', 5)

        expect(vending_machine.items.object_id).to eq(original_items_object_id)
      end
    end

    context 'when adding a new item' do
      it 'adds the item with correct attributes and returns success message' do
        message = vending_machine.load_item('Water', 10, 125)

        expect(message).to eq('Successfully added new item: Water - €1.25 (10 units)')

        water = vending_machine.items.find { |item| item.name == 'Water' }
        expect(water).not_to be_nil
        expect(water.price).to eq(125)
        expect(water.quantity).to eq(10)
      end

      it 'increases the items collection size' do
        initial_size = vending_machine.items.size
        vending_machine.load_item('Water', 5, 100)

        expect(vending_machine.items.size).to eq(initial_size + 1)
      end
    end

    context 'when validation fails' do
      it 'returns error for invalid quantity (zero or negative)' do
        initial_quantity = vending_machine.items.first.quantity
        
        message_zero = vending_machine.load_item('Coke', 0)
        expect(message_zero).to eq('Invalid quantity. Please provide a positive number.')
        
        message_negative = vending_machine.load_item('Coke', -5)
        expect(message_negative).to eq('Invalid quantity. Please provide a positive number.')
        
        expect(vending_machine.items.first.quantity).to eq(initial_quantity)
      end

      it 'returns error when adding new item without price' do
        initial_size = vending_machine.items.size
        message = vending_machine.load_item('Water', 5)

        expect(message).to eq('Price required for new item')
        expect(vending_machine.items.size).to eq(initial_size)
      end

      it 'returns error for invalid price (nil, zero, or negative)' do
        initial_size = vending_machine.items.size
        
        message_nil = vending_machine.load_item('Water', 5, nil)
        expect(message_nil).to eq('Price required for new item')
        
        message_zero = vending_machine.load_item('Water', 5, 0)
        expect(message_zero).to eq('Invalid price. Price must be positive.')
        
        message_negative = vending_machine.load_item('Water', 5, -100)
        expect(message_negative).to eq('Invalid price. Price must be positive.')
        
        expect(vending_machine.items.size).to eq(initial_size)
      end
    end

    context 'edge cases' do
      it 'handles invalid item names (empty or nil)' do
        message_empty = vending_machine.load_item('', 5, 100)
        expect(message_empty).to eq('Invalid item name')
        
        message_nil = vending_machine.load_item(nil, 5, 100)
        expect(message_nil).to eq('Invalid item name')
      end

      it 'handles very large quantities' do
        message = vending_machine.load_item('Coke', 1_000_000)

        expect(message).to eq('Successfully added 1000000 units to Coke. New quantity: 1000001')
        expect(vending_machine.items.first.quantity).to eq(1_000_001)
      end
    end

    context 'integration with ItemLoader' do
      it 'delegates to ItemLoader for processing' do
        item_loader = instance_double('ItemLoader')
        allow(item_loader).to receive(:load_item).and_return(['Success message', items])

        custom_machine = VendingMachine.new(items, balance, PaymentProcessor.new,
                                            SingleUserSessionManager.new, item_loader, nil)

        expect(item_loader).to receive(:load_item).with(items, hash_including('Coke' => items[0]), 'Coke', 5, nil)
        custom_machine.load_item('Coke', 5)
      end
    end
  end

  describe '#display_stock' do
    let(:vending_machine) { VendingMachine.new(items, balance) }

    context 'when items are available' do
      it 'displays all items with correct formatting' do
        result = vending_machine.display_stock

        expect(result).to include('Coke: 1 units @ €1.50')
        expect(result).to include('Pepsi: 1 units @ €1.75')
      end

      it 'returns multiline string with one item per line' do
        result = vending_machine.display_stock
        lines = result.split("\n")

        expect(lines.size).to eq(2) # Two items
        expect(lines[0]).to match(/^Coke:/)
        expect(lines[1]).to match(/^Pepsi:/)
      end

      it 'displays items with zero quantity' do
        zero_quantity_items = [
          Item.new('OutOfStock', 150, 0),
          Item.new('Available', 100, 5)
        ]
        machine = VendingMachine.new(zero_quantity_items, balance)

        result = machine.display_stock

        expect(result).to include('OutOfStock: 0 units @ €1.50')
        expect(result).to include('Available: 5 units @ €1.00')
      end
    end

    context 'when no items are available' do
      it 'returns appropriate message for empty items array' do
        empty_machine = VendingMachine.new([], balance)

        result = empty_machine.display_stock

        expect(result).to eq('No items available')
      end
    end

    context 'formatting edge cases' do
      it 'handles various price amounts with correct decimal places' do
        test_items = [
          Item.new('Cheap', 5, 1),      # €0.05
          Item.new('Normal', 150, 1),   # €1.50
          Item.new('Expensive', 9999, 1) # €99.99
        ]
        machine = VendingMachine.new(test_items, balance)

        result = machine.display_stock
        lines = result.split("\n")

        expect(result).to include('Cheap: 1 units @ €0.05')
        expect(result).to include('Normal: 1 units @ €1.50')
        expect(result).to include('Expensive: 1 units @ €99.99')
        
        # All prices should have 2 decimal places
        lines.each do |line|
          expect(line).to match(/€\d+\.\d{2}$/)
        end
      end
    end

    context 'after reload operations' do
      it 'reflects updated quantities after reload' do
        vending_machine.load_item('Coke', 5)

        result = vending_machine.display_stock

        expect(result).to include('Coke: 6 units @ €1.50')
      end

      it 'includes newly added items' do
        vending_machine.load_item('Water', 10, 125)

        result = vending_machine.display_stock

        expect(result).to include('Water: 10 units @ €1.25')
        expect(result.split("\n").size).to eq(3) # Original 2 + new item
      end
    end
  end

  describe '#reload_change' do
    let(:vending_machine) { VendingMachine.new(items, balance) }

    context 'when adding valid coins' do
      it 'adds coins to the balance and updates specific counts' do
        initial_100_count = vending_machine.balance.amount[100]
        initial_50_count = vending_machine.balance.amount[50]
        initial_balance = vending_machine.balance.calculate_total_amount
        
        coins_to_add = { 100 => 3, 50 => 2 }
        message = vending_machine.reload_change(coins_to_add)

        expect(message).to include('Successfully added coins')
        expect(vending_machine.balance.calculate_total_amount).to eq(initial_balance + 400)
        expect(vending_machine.balance.amount[100]).to eq(initial_100_count + 3)
        expect(vending_machine.balance.amount[50]).to eq(initial_50_count + 2)
      end
    end

    context 'when adding coins with invalid denominations' do
      it 'returns an error message' do
        coins_to_add = { 999 => 1 }
        message = vending_machine.reload_change(coins_to_add)

        expect(message).to include('Invalid coin denomination')
      end
    end

    context 'when adding coins with negative quantities' do
      it 'returns an error message' do
        coins_to_add = { 100 => -5 }
        message = vending_machine.reload_change(coins_to_add)

        expect(message).to include('must be positive')
      end
    end
  end

  describe 'purchasing an item' do
    context 'given an item name & balance' do
      let(:selected_item) { Item.new('Coke', 150, 1) }

      context 'when the item is available' do
        context 'when the user pays more than the item price' do
          it 'returns the item & balance' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.purchase_item('Coke',
                                                 { 200 => 1 })).to eq("Thank you for your purchase of #{selected_item.name}. Please collect your item and change: 1 x 50c")
          end

          it 'properly updates the machine balance with correct coin denominations' do
            vending_machine = VendingMachine.new(items, balance)
            initial_balance = vending_machine.balance.amount.dup

            vending_machine.purchase_item('Coke', { 200 => 1 })

            # Verify that the balance has been updated
            expect(vending_machine.balance.amount).not_to eq(initial_balance)

            # Verify that the total amount is correct (should be initial + 200 - 50 change)
            expected_total = initial_balance.sum { |denomination, count| denomination * count } + 200 - 50
            expect(vending_machine.balance.calculate_total_amount).to eq(expected_total)
          end

          it 'decrements the item quantity after successful purchase' do
            vending_machine = VendingMachine.new(items, balance)
            coke_item = vending_machine.items.find { |item| item.name == 'Coke' }
            initial_quantity = coke_item.quantity

            vending_machine.purchase_item('Coke', { 200 => 1 })

            expect(coke_item.quantity).to eq(initial_quantity - 1)
          end
        end

        context 'when the user pays the exact amount' do
          it 'returns the item & no change is given & it also decrements the item quantity' do
            vending_machine = VendingMachine.new(items, balance)
            coke_item = vending_machine.items.find { |item| item.name == 'Coke' }
            initial_quantity = coke_item.quantity

            expect(vending_machine.purchase_item('Coke',
                                                 { 100 => 1,
                                                   50 => 1 })).to eq('Thank you for your purchase of Coke. Please collect your item.')

            expect(coke_item.quantity).to eq(initial_quantity - 1)
          end
        end

        context 'when the user pays less than the item price' do
          it 'clearly specifies the remaining amount pending' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.purchase_item('Coke',
                                                 { 100 => 1 })).to eq('You need to pay 50 more cents to purchase Coke')
          end

          it 'does not decrement the item quantity for failed purchase' do
            vending_machine = VendingMachine.new(items, balance)
            coke_item = vending_machine.items.find { |item| item.name == 'Coke' }
            initial_quantity = coke_item.quantity

            vending_machine.purchase_item('Coke', { 100 => 1 })

            expect(coke_item.quantity).to eq(initial_quantity)
          end
        end


        context 'when invalid coin denominations are provided' do
          it 'returns error for various invalid denomination scenarios' do
            vending_machine = VendingMachine.new(items, balance)
            
            # Single invalid denomination
            expect(vending_machine.purchase_item('Coke', { 25 => 1 }))
              .to eq('Invalid coin denomination in payment: [25]')
            
            # Multiple invalid denominations
            expect(vending_machine.purchase_item('Coke', { 25 => 1, 75 => 1 }))
              .to eq('Invalid coin denomination in payment: [25, 75]')
            
            # Mixed valid and invalid
            expect(vending_machine.purchase_item('Coke', { 100 => 1, 25 => 1 }))
              .to eq('Invalid coin denomination in payment: [25]')
          end
        end
      end
    end
  end

  describe 'Session-based API' do
    before do
      @items = [Item.new('Coke', 150, 2)]
      @balance = Change.new({ 100 => 2, 50 => 2, 10 => 5 })
      @machine = VendingMachine.new(@items, @balance)
    end

    it 'handles full happy path: start, insert, complete' do
      start = @machine.start_purchase('Coke')
      expect(start).to include('Please insert €1.50')
      @machine.instance_variable_get(:@current_session_id)
      pay1 = @machine.insert_payment({ 100 => 1 })
      expect(pay1).to include('Please insert 50 more cents')
      pay2 = @machine.insert_payment({ 50 => 1 })
      expect(pay2).to include('Thank you for your purchase')
    end

    it 'handles partial payment and accumulation' do
      @machine.start_purchase('Coke')
      @machine.insert_payment({ 50 => 1 })
      msg = @machine.insert_payment({ 100 => 1 })
      expect(msg).to include('Thank you for your purchase')
    end

    it 'returns error if item not found' do
      msg = @machine.start_purchase('Pepsi')
      expect(msg).to eq('Item not found')
    end

    it 'old purchase_item API still works' do
      result = @machine.purchase_item('Coke', { 200 => 1 })
      expect(result).to include('Thank you for your purchase')
    end

    it 'maintains session after invalid denomination entry and allows correction' do
      @machine.start_purchase('Coke')

      # First payment with invalid denomination
      result1 = @machine.insert_payment({ 25 => 1 })
      expect(result1).to eq('Invalid coin denomination in payment: [25]')

      # Session should still be active, try with valid denomination
      result2 = @machine.insert_payment({ 100 => 1 })
      expect(result2).to include('Please insert 50 more cents')

      # Complete the payment
      result3 = @machine.insert_payment({ 50 => 1 })
      expect(result3).to include('Thank you for your purchase')
    end

  end

  describe 'CLI integration scenarios' do
    it 'handles Euro pricing correctly' do
      # Simulate CLI setup with Euro prices in cents
      items = [
        Item.new('Coke', 150, 5),      # €1.50 = 150 cents
        Item.new('Chips', 100, 3),     # €1.00 = 100 cents
        Item.new('Candy', 75, 8),      # €0.75 = 75 cents
        Item.new('Water', 125, 2)      # €1.25 = 125 cents
      ]
      balance = Change.new({ 50 => 6, 10 => 10, 20 => 10, 100 => 2, 200 => 1, 5 => 10, 2 => 10, 1 => 2 })
      machine = VendingMachine.new(items, balance)

      # Test the exact scenario that was failing
      result = machine.purchase_item('Chips', { 200 => 1 })
      expect(result).to eq('Thank you for your purchase of Chips. Please collect your item and change: 1 x 100c')
    end

    it 'handles insufficient change scenario using session API' do
      # Machine has limited change - only €2 coin available
      items = [
        Item.new('Chips', 100, 3) # €1.00 item
      ]
      balance = Change.new({ 200 => 1 }) # Only one €2 coin, no smaller denominations
      machine = VendingMachine.new(items, balance)

      # Start purchase session and try to pay with €2 for €1 item
      machine.start_purchase('Chips')
      result = machine.insert_payment({ 200 => 1 })

      # Should auto-cancel and refund payment
      expect(result).to eq('Cannot provide change. Payment refunded: 1 x €2. Please try with exact amount.')
    end
  end

  describe '#load_item' do
    before do
      @items = [Item.new('Coke', 150, 2)]
      @balance = Change.new({ 100 => 2, 50 => 2 })
      @machine = VendingMachine.new(@items, @balance)
    end

    it 'delegates to reload_manager and updates items' do
      result = @machine.load_item('Coke', 5)
      expect(result).to eq('Successfully added 5 units to Coke. New quantity: 7')
      expect(@machine.items.first.quantity).to eq(7)
    end

    it 'adds new item when not found' do
      result = @machine.load_item('Water', 10, 125)
      expect(result).to eq('Successfully added new item: Water - €1.25 (10 units)')
      expect(@machine.items.size).to eq(2)
      expect(@machine.items.last.name).to eq('Water')
    end

    it 'returns error for invalid input' do
      result = @machine.load_item('Coke', -5)
      expect(result).to eq('Invalid quantity. Please provide a positive number.')
      expect(@machine.items.first.quantity).to eq(2) # Unchanged
    end
  end

  describe '#reload_change' do
    before do
      @items = []
      @balance = Change.new({ 50 => 2, 10 => 3 })
      @machine = VendingMachine.new(@items, @balance)
    end

    it 'delegates to reload_manager and updates balance' do
      initial_total = @machine.available_change
      result = @machine.reload_change({ 100 => 5, 50 => 3 })

      expect(result).to include('Successfully added coins')
      expect(@machine.available_change).to eq(initial_total + 650)
      expect(@machine.balance.amount[100]).to eq(5)
      expect(@machine.balance.amount[10]).to eq(3)
      expect(@machine.balance.amount[50]).to eq(5) # 2 + 3
    end

    it 'returns error for invalid denominations' do
      result = @machine.reload_change({ 25 => 5 })
      expect(result).to eq('Invalid coin denominations: [25]')
      expect(@machine.available_change).to eq(130) # Unchanged
    end

    it 'returns error for non-hash input' do
      result = @machine.reload_change('invalid')
      expect(result).to eq('Invalid input. Please provide a hash of coins.')
    end

    context 'integration with ChangeReloader' do
      it 'delegates to ChangeReloader for processing' do
        change_reloader = instance_double('ChangeReloader')
        allow(change_reloader).to receive(:reload_change).and_return(['Success message', @balance])

        custom_machine = VendingMachine.new(@items, @balance, PaymentProcessor.new,
                                            SingleUserSessionManager.new, nil, change_reloader)

        expect(change_reloader).to receive(:reload_change).with(@balance, { 100 => 5 })
        custom_machine.reload_change({ 100 => 5 })
      end
    end
  end

  describe '#display_stock' do
    it 'displays all items with quantities and prices' do
      items = [
        Item.new('Coke', 150, 5),
        Item.new('Chips', 100, 3)
      ]
      machine = VendingMachine.new(items, Change.new({ 50 => 1 }))

      stock = machine.display_stock
      expect(stock).to include('Coke: 5 units @ €1.50')
      expect(stock).to include('Chips: 3 units @ €1.00')
    end

    it 'returns message when no items in stock' do
      machine = VendingMachine.new([], Change.new({ 50 => 1 }))
      expect(machine.display_stock).to eq('No items available')
    end
  end

  describe 'reload integration' do
    it 'allows reload and purchase in sequence' do
      items = [Item.new('Coke', 150, 0)] # Out of stock
      balance = Change.new({ 50 => 1 }) # Limited change
      machine = VendingMachine.new(items, balance)

      # Cannot purchase when out of stock
      result = machine.purchase_item('Coke', { 200 => 1 })
      expect(result).to eq('Item not available')

      # Reload items
      reload_result = machine.load_item('Coke', 5)
      expect(reload_result).to include('Successfully added 5 units')

      # Reload change
      change_result = machine.reload_change({ 50 => 10 })
      expect(change_result).to include('Successfully added coins')

      # Now purchase should work
      purchase_result = machine.purchase_item('Coke', { 200 => 1 })
      expect(purchase_result).to include('Thank you for your purchase')
    end
  end

  describe '#balance_in_english' do
    context 'when balance has multiple denominations' do
      let(:vending_machine) { VendingMachine.new(items, balance) }

      it 'returns properly formatted English description of balance' do
        result = vending_machine.balance_in_english
        
        expect(result).to include('1 2 Euro coin')
        expect(result).to include('2 1 Euro coins')
        expect(result).to include('10 20-cent coins')
        expect(result).to include('10 10-cent coins')
        expect(result).to include('6 50-cent coins')
        expect(result).to include('10 5-cent coins')
        expect(result).to include('10 2-cent coins')
        expect(result).to include('2 1-cent coins')
      end

    end

    context 'when balance has single denomination coins' do
      let(:single_coin_balance) { Change.new({ 100 => 1 }) }
      let(:vending_machine) { VendingMachine.new(items, single_coin_balance) }

      it 'uses singular form for single coin' do
        result = vending_machine.balance_in_english
        expect(result).to eq('1 1 Euro coin')
      end
    end

    context 'when balance has multiple coins of same denomination' do
      let(:multiple_coins_balance) { Change.new({ 50 => 5 }) }
      let(:vending_machine) { VendingMachine.new(items, multiple_coins_balance) }

      it 'uses plural form for multiple coins' do
        result = vending_machine.balance_in_english
        expect(result).to eq('5 50-cent coins')
      end
    end

    context 'when balance is empty' do
      let(:empty_balance) { Change.new({}) }
      let(:vending_machine) { VendingMachine.new(items, empty_balance) }

      it 'returns no coins message' do
        result = vending_machine.balance_in_english
        expect(result).to eq('No coins')
      end
    end

    context 'when balance is nil or invalid' do
      it 'returns fallback message for nil or invalid balance' do
        machine_nil = VendingMachine.new(items, nil)
        expect(machine_nil.balance_in_english).to eq('No balance information')
        
        invalid_balance = double('InvalidBalance')
        machine_invalid = VendingMachine.new(items, invalid_balance)
        expect(machine_invalid.balance_in_english).to eq('No balance information')
      end
    end

    context 'edge cases with coin formatting' do
      let(:edge_case_balance) { Change.new({ 200 => 3, 1 => 1, 5 => 0 }) }
      let(:vending_machine) { VendingMachine.new(items, edge_case_balance) }

      it 'excludes coins with zero quantity' do
        result = vending_machine.balance_in_english
        expect(result).not_to include('5-cent')
        expect(result).to include('3 2 Euro coins')
        expect(result).to include('1 1-cent coin')
      end
    end
  end

  describe '#available_change' do
    context 'when balance has multiple denominations' do
      let(:vending_machine) { VendingMachine.new(items, balance) }

      it 'returns total amount in cents' do
        result = vending_machine.available_change
        
        # Calculate expected total: 
        # 200*1 + 100*2 + 50*6 + 20*10 + 10*10 + 5*10 + 2*10 + 1*2
        # = 200 + 200 + 300 + 200 + 100 + 50 + 20 + 2 = 1072
        expect(result).to eq(1072)
      end

    end

    context 'when balance has single denomination' do
      let(:single_balance) { Change.new({ 100 => 5 }) }
      let(:vending_machine) { VendingMachine.new(items, single_balance) }

      it 'calculates correct total for single denomination' do
        result = vending_machine.available_change
        expect(result).to eq(500) # 100 * 5
      end
    end

    context 'when balance is empty' do
      let(:empty_balance) { Change.new({}) }
      let(:vending_machine) { VendingMachine.new(items, empty_balance) }

      it 'returns zero for empty balance' do
        result = vending_machine.available_change
        expect(result).to eq(0)
      end
    end

    context 'when balance is nil or invalid' do
      it 'returns zero for nil or invalid balance' do
        machine_nil = VendingMachine.new(items, nil)
        expect(machine_nil.available_change).to eq(0)
        
        invalid_balance = double('InvalidBalance')
        machine_invalid = VendingMachine.new(items, invalid_balance)
        expect(machine_invalid.available_change).to eq(0)
      end
    end

    context 'after balance changes from transactions' do
      let(:vending_machine) { VendingMachine.new(items, balance) }

      it 'reflects updated balance after successful purchase' do
        initial_change = vending_machine.available_change
        
        # Purchase item that costs 150c with 200c payment (50c change given)
        vending_machine.purchase_item('Coke', { 200 => 1 })
        
        # Balance should increase by 150c (200c received - 50c given as change)
        updated_change = vending_machine.available_change
        expect(updated_change).to eq(initial_change + 150)
      end

      it 'reflects updated balance after reloading change' do
        initial_change = vending_machine.available_change
        
        # Add more coins to balance
        vending_machine.reload_change({ 100 => 3, 50 => 2 })
        
        # Balance should increase by 400c (300 + 100)
        updated_change = vending_machine.available_change
        expect(updated_change).to eq(initial_change + 400)
      end
    end

    context 'consistency with balance calculation' do
      let(:large_balance) do
        Change.new({
          200 => 10,  # 2000c
          100 => 15,  # 1500c
          50 => 20,   # 1000c
          20 => 25,   # 500c
          10 => 30,   # 300c
          5 => 40,    # 200c
          2 => 50,    # 100c
          1 => 60     # 60c
        })
      end
      let(:vending_machine) { VendingMachine.new(items, large_balance) }

      it 'correctly calculates large balance totals' do
        result = vending_machine.available_change
        # Total: 2000 + 1500 + 1000 + 500 + 300 + 200 + 100 + 60 = 5660
        expect(result).to eq(5660)
      end
    end
  end

  describe '#complete_purchase' do
    before do
      @items = [Item.new('Coke', 150, 1), Item.new('Pepsi', 175, 1)]
      @balance = Change.new({
        50 => 6,
        10 => 10,
        20 => 10,
        100 => 2,
        200 => 1,
        5 => 10,
        2 => 10,
        1 => 2
      })
      @machine = VendingMachine.new(@items, @balance)
    end

    context 'when there is an active purchase session' do
      context 'with sufficient payment auto-completes' do
        it 'completes the purchase automatically when sufficient payment is inserted' do
          @machine.start_purchase('Coke')
          
          # When sufficient payment is inserted, purchase auto-completes
          result = @machine.insert_payment({ 200 => 1 })
          expect(result).to include('Thank you for your purchase of Coke')
          expect(result).to include('Please collect your item and change: 1 x 50c')
        end

        it 'decrements the item quantity' do
          initial_quantity = @machine.items.first.quantity
          @machine.start_purchase('Coke')
          @machine.insert_payment({ 200 => 1 })
          expect(@machine.items.first.quantity).to eq(initial_quantity - 1)
        end

        it 'updates the machine balance correctly' do
          initial_balance = @machine.balance.calculate_total_amount
          @machine.start_purchase('Coke')
          @machine.insert_payment({ 200 => 1 })
          # Added 200c, gave back 50c change, net increase of 150c
          expect(@machine.balance.calculate_total_amount).to eq(initial_balance + 150)
        end

        it 'clears the current session after auto-completion' do
          @machine.start_purchase('Coke')
          @machine.insert_payment({ 200 => 1 })  # Auto-completes
          # Attempting to complete again should fail
          result = @machine.complete_purchase
          expect(result).to eq('No active purchase session')
        end
      end

      context 'with exact payment' do
        it 'completes the purchase without change message' do
          @machine.start_purchase('Coke')
          result = @machine.insert_payment({ 100 => 1, 50 => 1 })
          expect(result).to eq('Thank you for your purchase of Coke. Please collect your item.')
        end

        it 'updates balance with exact payment amount' do
          initial_balance = @machine.balance.calculate_total_amount
          @machine.start_purchase('Coke')
          @machine.insert_payment({ 100 => 1, 50 => 1 })
          expect(@machine.balance.calculate_total_amount).to eq(initial_balance + 150)
        end
      end

      context 'with insufficient payment and manual complete' do
        it 'returns payment status when attempting to complete with insufficient funds' do
          @machine.start_purchase('Coke')
          @machine.insert_payment({ 100 => 1 })
          result = @machine.complete_purchase
          expect(result).to eq('Insufficient funds')
        end

        it 'does not decrement item quantity with insufficient payment' do
          initial_quantity = @machine.items.first.quantity
          @machine.start_purchase('Coke')
          @machine.insert_payment({ 100 => 1 })
          @machine.complete_purchase
          expect(@machine.items.first.quantity).to eq(initial_quantity)
        end

        it 'does not update machine balance with insufficient payment' do
          initial_balance = @machine.balance.calculate_total_amount
          @machine.start_purchase('Coke')
          @machine.insert_payment({ 100 => 1 })
          @machine.complete_purchase
          expect(@machine.balance.calculate_total_amount).to eq(initial_balance)
        end

        it 'allows adding more payment to complete the purchase' do
          @machine.start_purchase('Coke')
          result1 = @machine.insert_payment({ 100 => 1 })
          expect(result1).to include('50 more')
          
          # Add remaining payment - should auto-complete
          result2 = @machine.insert_payment({ 50 => 1 })
          expect(result2).to include('Thank you for your purchase')
        end
      end
    end

    context 'when there is no active purchase session' do
      it 'returns appropriate error message' do
        result = @machine.complete_purchase
        expect(result).to eq('No active purchase session')
      end

      it 'does not affect items or balance' do
        initial_items = @machine.items.map(&:quantity)
        initial_balance = @machine.balance.calculate_total_amount
        
        @machine.complete_purchase
        
        expect(@machine.items.map(&:quantity)).to eq(initial_items)
        expect(@machine.balance.calculate_total_amount).to eq(initial_balance)
      end
    end

  end

  describe '#cancel_purchase' do
    before do
      @items = [Item.new('Coke', 150, 1), Item.new('Pepsi', 175, 1)]
      @balance = Change.new({
        50 => 6,
        10 => 10,
        20 => 10,
        100 => 2,
        200 => 1,
        5 => 10,
        2 => 10,
        1 => 2
      })
      @machine = VendingMachine.new(@items, @balance)
    end

    context 'when there is an active purchase session' do
      context 'with partial payment' do
        before do
          @machine.start_purchase('Coke')
          @machine.insert_payment({ 100 => 1 })
        end

        it 'cancels the session and returns refund message' do
          result = @machine.cancel_purchase
          expect(result).to eq('Purchase cancelled. Money returned: 1 x €1')
        end

        it 'does not decrement item quantity' do
          initial_quantity = @machine.items.first.quantity
          @machine.cancel_purchase
          expect(@machine.items.first.quantity).to eq(initial_quantity)
        end

        it 'does not add payment to machine balance' do
          initial_balance = @machine.balance.calculate_total_amount
          @machine.cancel_purchase
          expect(@machine.balance.calculate_total_amount).to eq(initial_balance)
        end

        it 'clears the current session' do
          @machine.cancel_purchase
          # Should be able to start a new purchase
          result = @machine.start_purchase('Pepsi')
          expect(result).to include('Pepsi')
        end
      end

      context 'with multiple coin payments' do
        before do
          @machine.start_purchase('Pepsi')
          @machine.insert_payment({ 50 => 2, 20 => 2, 10 => 1 })
        end

        it 'returns all inserted coins in the refund' do
          result = @machine.cancel_purchase
          expect(result).to include('2 x 50c')
          expect(result).to include('2 x 20c')
          expect(result).to include('1 x 10c')
        end
      end

      context 'with no payment yet' do
        before do
          @machine.start_purchase('Coke')
        end

        it 'cancels with appropriate message' do
          result = @machine.cancel_purchase
          expect(result).to eq('Purchase cancelled. No money to return.')
        end

        it 'clears the session' do
          @machine.cancel_purchase
          result = @machine.complete_purchase
          expect(result).to eq('No active purchase session')
        end
      end

      context 'with full payment but not completed' do
        it 'auto-completes when full payment is inserted' do
          @machine.start_purchase('Coke')
          # When exact payment is inserted, purchase auto-completes
          result = @machine.insert_payment({ 100 => 1, 50 => 1 })
          expect(result).to include('Thank you for your purchase')
        end
      end
    end

    context 'when there is no active purchase session' do
      it 'returns appropriate error message' do
        result = @machine.cancel_purchase
        expect(result).to eq('No active purchase session')
      end

      it 'does not affect items or balance' do
        initial_items = @machine.items.map(&:quantity)
        initial_balance = @machine.balance.calculate_total_amount
        
        @machine.cancel_purchase
        
        expect(@machine.items.map(&:quantity)).to eq(initial_items)
        expect(@machine.balance.calculate_total_amount).to eq(initial_balance)
      end
    end

    context 'edge cases' do
      it 'handles double cancellation gracefully' do
        @machine.start_purchase('Coke')
        @machine.insert_payment({ 50 => 1 })
        
        @machine.cancel_purchase
        result = @machine.cancel_purchase
        expect(result).to eq('No active purchase session')
      end

      it 'allows starting new purchase after cancellation' do
        @machine.start_purchase('Coke')
        @machine.insert_payment({ 100 => 1 })
        @machine.cancel_purchase
        
        # Start new purchase
        result = @machine.start_purchase('Pepsi')
        expect(result).to be_a(String)
        expect(result).to include('Pepsi')
      end

      it 'handles cancellation after item becomes unavailable' do
        # Start purchase when item is available
        @machine.start_purchase('Coke')
        @machine.insert_payment({ 100 => 1 })
        
        # Simulate item becoming unavailable
        @machine.items.first.quantity = 0
        
        # Should still be able to cancel and get refund
        result = @machine.cancel_purchase
        expect(result).to include('1 x €1')
      end
    end

    context 'transaction integrity' do
      it 'ensures atomicity - either completes fully or rolls back completely' do
        initial_balance = @machine.balance.calculate_total_amount
        initial_quantity = @machine.items.first.quantity
        
        @machine.start_purchase('Coke')
        # Add partial payment so it doesn't auto-complete
        @machine.insert_payment({ 100 => 1 })
        @machine.cancel_purchase
        
        # Everything should be rolled back to initial state
        expect(@machine.balance.calculate_total_amount).to eq(initial_balance)
        expect(@machine.items.first.quantity).to eq(initial_quantity)
      end
    end
  end
end
