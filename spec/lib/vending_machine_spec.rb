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
                                                 50 => 1 })).to eq("Thank you for your purchase of Coke. Please collect your item.")

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
            expect(vending_machine.purchase_item('Coke', { 200 => 1 })).to eq("Thank you for your purchase of Coke. Please collect your item and change: 1 x 50c")
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
            expect(vending_machine.purchase_item('Coke', { 25 => 1 })).to eq('Invalid coin denomination in payment: [25]')
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
      session_id = @machine.instance_variable_get(:@current_session_id)
      pay1 = @machine.insert_payment({100 => 1})
      expect(pay1).to include('Please insert 50 more cents')
      pay2 = @machine.insert_payment({50 => 1})
      expect(pay2).to include('Thank you for your purchase')
    end

    it 'handles partial payment and accumulation' do
      @machine.start_purchase('Coke')
      @machine.insert_payment({50 => 1})
      msg = @machine.insert_payment({100 => 1})
      expect(msg).to include('Thank you for your purchase')
    end

    it 'returns error if item not found' do
      msg = @machine.start_purchase('Pepsi')
      expect(msg).to eq('Item not found')
    end

    it 'old purchase_item API still works' do
      result = @machine.purchase_item('Coke', {200 => 1})
      expect(result).to include('Thank you for your purchase')
    end

    it 'maintains session after invalid denomination entry and allows correction' do
      @machine.start_purchase('Coke')

      # First payment with invalid denomination
      result1 = @machine.insert_payment({25 => 1})
      expect(result1).to eq('Invalid coin denomination in payment: [25]')

      # Session should still be active, try with valid denomination
      result2 = @machine.insert_payment({100 => 1})
      expect(result2).to include('Please insert 50 more cents')

      # Complete the payment
      result3 = @machine.insert_payment({50 => 1})
      expect(result3).to include('Thank you for your purchase')
    end

    context 'consistency between session and direct purchase' do
      it 'produces identical results for same payment scenario' do
        # Test with session-based API
        @machine.start_purchase('Coke')
        session_result = @machine.insert_payment({200 => 1})

        # Reset machine for direct purchase
        @machine2 = VendingMachine.new(@items, @balance)
        direct_result = @machine2.purchase_item('Coke', {200 => 1})

        expect(session_result).to eq(direct_result)
      end

      it 'updates balance identically in both flows' do
        # Session-based purchase
        @machine.start_purchase('Coke')
        @machine.insert_payment({200 => 1})
        session_balance = @machine.balance.calculate_total_amount

        # Direct purchase
        @machine2 = VendingMachine.new(@items, @balance)
        @machine2.purchase_item('Coke', {200 => 1})
        direct_balance = @machine2.balance.calculate_total_amount

        expect(session_balance).to eq(direct_balance)
      end
    end
  end

  describe 'CLI integration scenarios' do
    it 'handles Euro pricing correctly' do
      # Simulate CLI setup with Euro prices in cents
      items = [
        Item.new("Coke", 150, 5),      # €1.50 = 150 cents
        Item.new("Chips", 100, 3),     # €1.00 = 100 cents
        Item.new("Candy", 75, 8),      # €0.75 = 75 cents
        Item.new("Water", 125, 2)      # €1.25 = 125 cents
      ]
      balance = Change.new({ 50 => 6, 10 => 10, 20 => 10, 100 => 2, 200 => 1, 5 => 10, 2 => 10, 1 => 2 })
      machine = VendingMachine.new(items, balance)

      # Test the exact scenario that was failing
      result = machine.purchase_item("Chips", {200 => 1})
      expect(result).to eq('Thank you for your purchase of Chips. Please collect your item and change: 1 x 100c')
    end

    it 'prevents incorrect pricing setup' do
      # This should fail if someone tries to use dollar amounts instead of cents
      items = [
        Item.new("Chips", 1.00, 3),    # Wrong: should be 100 cents, not 1.00
      ]
      balance = Change.new({ 100 => 2, 200 => 1 })
      machine = VendingMachine.new(items, balance)

      # With 1.00 price, 200 cents payment should be rejected because machine can't make 199 cents change
      result = machine.purchase_item("Chips", {200 => 1})
      expect(result).to eq('Cannot provide change with available coins. Please use exact amount.')
    end
  end
end
