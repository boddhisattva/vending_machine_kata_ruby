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

  describe '#reload_item' do
    let(:vending_machine) { VendingMachine.new(items, balance) }

    context 'when reloading an existing item' do
      it 'increases the quantity and returns success message' do
        initial_quantity = vending_machine.items.first.quantity
        message = vending_machine.reload_item('Coke', 5)

        expect(message).to eq('Successfully added 5 units to Coke. New quantity: 6')
        expect(vending_machine.items.first.quantity).to eq(initial_quantity + 5)
      end

      it 'ignores price parameter for existing items' do
        message = vending_machine.reload_item('Coke', 3, 999)

        expect(message).to eq('Successfully added 3 units to Coke. New quantity: 4')
        expect(vending_machine.items.first.price).to eq(150) # Price unchanged
      end

      it 'maintains reference to the same items array' do
        original_items_object_id = vending_machine.items.object_id
        vending_machine.reload_item('Coke', 5)

        expect(vending_machine.items.object_id).to eq(original_items_object_id)
      end
    end

    context 'when adding a new item' do
      it 'adds the item with correct attributes and returns success message' do
        message = vending_machine.reload_item('Water', 10, 125)

        expect(message).to eq('Successfully added new item: Water - €1.25 (10 units)')

        water = vending_machine.items.find { |item| item.name == 'Water' }
        expect(water).not_to be_nil
        expect(water.price).to eq(125)
        expect(water.quantity).to eq(10)
      end

      it 'increases the items collection size' do
        initial_size = vending_machine.items.size
        vending_machine.reload_item('Water', 5, 100)

        expect(vending_machine.items.size).to eq(initial_size + 1)
      end
    end

    context 'when validation fails' do
      it 'returns error for zero quantity' do
        initial_quantity = vending_machine.items.first.quantity
        message = vending_machine.reload_item('Coke', 0)

        expect(message).to eq('Invalid quantity. Please provide a positive number.')
        expect(vending_machine.items.first.quantity).to eq(initial_quantity)
      end

      it 'returns error for negative quantity' do
        initial_quantity = vending_machine.items.first.quantity
        message = vending_machine.reload_item('Coke', -5)

        expect(message).to eq('Invalid quantity. Please provide a positive number.')
        expect(vending_machine.items.first.quantity).to eq(initial_quantity)
      end

      it 'returns error when adding new item without price' do
        initial_size = vending_machine.items.size
        message = vending_machine.reload_item('Water', 5)

        expect(message).to eq('Price required for new item')
        expect(vending_machine.items.size).to eq(initial_size)
      end

      it 'returns error when adding new item with nil price' do
        message = vending_machine.reload_item('Water', 5, nil)

        expect(message).to eq('Price required for new item')
      end

      it 'returns error for invalid price (zero)' do
        message = vending_machine.reload_item('Water', 5, 0)

        expect(message).to eq('Invalid price. Price must be positive.')
      end

      it 'returns error for negative price' do
        message = vending_machine.reload_item('Water', 5, -100)

        expect(message).to eq('Invalid price. Price must be positive.')
      end
    end

    context 'edge cases' do
      it 'handles empty item name gracefully' do
        message = vending_machine.reload_item('', 5, 100)

        expect(message).to eq('Invalid item name')
      end

      it 'handles nil item name' do
        message = vending_machine.reload_item(nil, 5, 100)

        expect(message).to eq('Invalid item name')
      end

      it 'handles very large quantities' do
        message = vending_machine.reload_item('Coke', 1_000_000)

        expect(message).to eq('Successfully added 1000000 units to Coke. New quantity: 1000001')
        expect(vending_machine.items.first.quantity).to eq(1_000_001)
      end
    end

    context 'integration with ReloadManager' do
      it 'delegates to ReloadManager for processing' do
        reload_manager = instance_double('ReloadManager')
        allow(reload_manager).to receive(:reload_item).and_return(['Success message', items])

        custom_machine = VendingMachine.new(items, balance, PaymentProcessor.new,
                                            SingleUserSessionManager.new, reload_manager)

        expect(reload_manager).to receive(:reload_item).with(items, hash_including('Coke' => items[0]), 'Coke', 5, nil)
        custom_machine.reload_item('Coke', 5)
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

      it 'formats prices correctly from cents to euros' do
        test_items = [
          Item.new('Candy', 75, 10),   # €0.75
          Item.new('Chips', 100, 5),   # €1.00
          Item.new('Soda', 225, 3)     # €2.25
        ]
        machine = VendingMachine.new(test_items, balance)

        result = machine.display_stock

        expect(result).to include('Candy: 10 units @ €0.75')
        expect(result).to include('Chips: 5 units @ €1.00')
        expect(result).to include('Soda: 3 units @ €2.25')
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
      it 'handles single digit cent amounts correctly' do
        test_items = [Item.new('Cheap', 5, 1)] # €0.05
        machine = VendingMachine.new(test_items, balance)

        result = machine.display_stock

        expect(result).to eq('Cheap: 1 units @ €0.05')
      end

      it 'handles large prices correctly' do
        test_items = [Item.new('Expensive', 9999, 1)] # €99.99
        machine = VendingMachine.new(test_items, balance)

        result = machine.display_stock

        expect(result).to eq('Expensive: 1 units @ €99.99')
      end

      it 'maintains consistent decimal places' do
        test_items = [
          Item.new('Item1', 100, 1),  # €1.00
          Item.new('Item2', 150, 1),  # €1.50
          Item.new('Item3', 5, 1)     # €0.05
        ]
        machine = VendingMachine.new(test_items, balance)

        result = machine.display_stock
        lines = result.split("\n")

        # All prices should have 2 decimal places
        lines.each do |line|
          expect(line).to match(/€\d+\.\d{2}$/)
        end
      end
    end

    context 'after reload operations' do
      it 'reflects updated quantities after reload' do
        vending_machine.reload_item('Coke', 5)

        result = vending_machine.display_stock

        expect(result).to include('Coke: 6 units @ €1.50')
      end

      it 'includes newly added items' do
        vending_machine.reload_item('Water', 10, 125)

        result = vending_machine.display_stock

        expect(result).to include('Water: 10 units @ €1.25')
        expect(result.split("\n").size).to eq(3) # Original 2 + new item
      end
    end
  end

  describe '#reload_change' do
    let(:vending_machine) { VendingMachine.new(items, balance) }

    context 'when adding valid coins' do
      it 'adds coins to the balance and returns success message' do
        coins_to_add = { 100 => 5, 50 => 10 }

        initial_balance = vending_machine.balance.calculate_total_amount
        message = vending_machine.reload_change(coins_to_add)

        expect(message).to include('Successfully added coins')
        expect(vending_machine.balance.calculate_total_amount).to eq(initial_balance + 1000)
      end

      it 'updates the specific coin counts in balance' do
        initial_100_count = vending_machine.balance.amount[100]
        initial_50_count = vending_machine.balance.amount[50]

        coins_to_add = { 100 => 3, 50 => 2 }
        vending_machine.reload_change(coins_to_add)

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

        context 'when the quantity of the item is 0' do
          let(:item_quantity) { 0 }
          let(:items) { [Item.new('Coke', 150, item_quantity)] }
          it 'returns an error message' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.purchase_item('Coke',
                                                 150)).to eq('Item not available')
          end
        end

        context 'when purchasing the last item' do
          let(:items) { [Item.new('Coke', 150, 1)] }
          it 'decrements quantity to 0 and item becomes unavailable' do
            vending_machine = VendingMachine.new(items, balance)
            coke_item = vending_machine.items.find { |item| item.name == 'Coke' }

            # First purchase should succeed
            expect(vending_machine.purchase_item('Coke',
                                                 { 200 => 1 })).to eq('Thank you for your purchase of Coke. Please collect your item and change: 1 x 50c')
            expect(coke_item.quantity).to eq(0)

            # Second purchase should fail
            expect(vending_machine.purchase_item('Coke', { 200 => 1 })).to eq('Item not available')
          end
        end

        context 'when the machine does not have enough change' do
          it 'should ask to render exact amount' do
          end
        end

        context 'when invalid coin denominations are provided' do
          it 'returns an error message for invalid denominations' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.purchase_item('Coke',
                                                 { 25 => 1 })).to eq('Invalid coin denomination in payment: [25]')
          end

          it 'returns an error message for multiple invalid denominations' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.purchase_item('Coke',
                                                 { 25 => 1,
                                                   75 => 1 })).to eq('Invalid coin denomination in payment: [25, 75]')
          end

          it 'returns an error message for mixed valid and invalid denominations' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.purchase_item('Coke',
                                                 { 100 => 1,
                                                   25 => 1 })).to eq('Invalid coin denomination in payment: [25]')
          end
        end

        # context 'change given in valid amount type' do
        # end check the coins specified are valid
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
      expect(start).to include('Please insert 150 cents')
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

    context 'consistency between session and direct purchase' do
      it 'produces identical results for same payment scenario' do
        # Test with session-based API
        @machine.start_purchase('Coke')
        session_result = @machine.insert_payment({ 200 => 1 })

        # Reset machine for direct purchase
        @machine2 = VendingMachine.new(@items, @balance)
        direct_result = @machine2.purchase_item('Coke', { 200 => 1 })

        expect(session_result).to eq(direct_result)
      end

      it 'updates balance identically in both flows' do
        # Session-based purchase
        @machine.start_purchase('Coke')
        @machine.insert_payment({ 200 => 1 })
        session_balance = @machine.balance.calculate_total_amount

        # Direct purchase
        @machine2 = VendingMachine.new(@items, @balance)
        @machine2.purchase_item('Coke', { 200 => 1 })
        direct_balance = @machine2.balance.calculate_total_amount

        expect(session_balance).to eq(direct_balance)
      end
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

    it 'prevents incorrect pricing setup' do
      # This should fail if someone tries to use dollar amounts instead of cents
      items = [
        Item.new('Chips', 1.00, 3) # Wrong: should be 100 cents, not 1.00
      ]
      balance = Change.new({ 100 => 2, 200 => 1 })
      machine = VendingMachine.new(items, balance)

      # With 1.00 price, 200 cents payment should be rejected because machine can't make 199 cents change
      result = machine.purchase_item('Chips', { 200 => 1 })
      expect(result).to eq('Cannot provide change with available coins. Please use exact amount.')
    end
  end

  describe '#reload_item' do
    before do
      @items = [Item.new('Coke', 150, 2)]
      @balance = Change.new({ 100 => 2, 50 => 2 })
      @machine = VendingMachine.new(@items, @balance)
    end

    it 'delegates to reload_manager and updates items' do
      result = @machine.reload_item('Coke', 5)
      expect(result).to eq('Successfully added 5 units to Coke. New quantity: 7')
      expect(@machine.items.first.quantity).to eq(7)
    end

    it 'adds new item when not found' do
      result = @machine.reload_item('Water', 10, 125)
      expect(result).to eq('Successfully added new item: Water - €1.25 (10 units)')
      expect(@machine.items.size).to eq(2)
      expect(@machine.items.last.name).to eq('Water')
    end

    it 'returns error for invalid input' do
      result = @machine.reload_item('Coke', -5)
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
      reload_result = machine.reload_item('Coke', 5)
      expect(reload_result).to include('Successfully added 5 units')

      # Reload change
      change_result = machine.reload_change({ 50 => 10 })
      expect(change_result).to include('Successfully added coins')

      # Now purchase should work
      purchase_result = machine.purchase_item('Coke', { 200 => 1 })
      expect(purchase_result).to include('Thank you for your purchase')
    end
  end
end
