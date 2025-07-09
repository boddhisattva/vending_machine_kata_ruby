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

  describe 'selecting an item' do
    context 'given an item name & balance' do
      let(:selected_item) { Item.new('Coke', 150, 1) }

      context 'when the item is available' do
        context 'when the user pays more than the item price' do
          it 'returns the item & balance' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke',
                                               { 200 => 1 })).to eq("Thank you for your purchase of #{selected_item.name}. Please collect your item and change: 50")
          end

          it 'properly updates the machine balance with correct coin denominations' do
            vending_machine = VendingMachine.new(items, balance)
            initial_balance = vending_machine.balance.amount.dup

            vending_machine.select_item('Coke', { 200 => 1 })

            # Verify that the balance has been updated
            expect(vending_machine.balance.amount).not_to eq(initial_balance)

            # Verify that the total amount is correct (should be initial + 200 - 50 change)
            expected_total = initial_balance.sum { |denomination, count| denomination * count } + 200 - 50
            expect(vending_machine.balance.calculate_total_amount).to eq(expected_total)
          end
        end

        context 'when the user pays the exact amount' do
          it 'returns the item & no change is given' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke',
                                               { 100 => 1,
                                                 50 => 1 })).to eq("Thank you for your purchase of #{selected_item.name}. Please collect your item.")
          end
        end

        context 'when the user pays less than the item price' do
          it 'clearly specifies the remaining amount pending' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke',
                                               { 100 => 1 })).to eq('You need to pay 50 more cents to purchase Coke')
          end
        end

        context 'when the quantity of the item is 0' do
          let(:item_quantity) { 0 }
          let(:items) { [Item.new('Coke', 150, item_quantity)] }
          it 'returns an error message' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke',
                                               150)).to eq('Item not available')
          end
        end

        context 'when the machine does not have enough change' do
          it 'should ask to render exact amount' do
          end
        end

        context 'when invalid coin denominations are provided' do
          it 'returns an error message for invalid denominations' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke', { 25 => 1 })).to eq('Invalid coin denomination in payment: [25]')
          end

          it 'returns an error message for multiple invalid denominations' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke',
                                               { 25 => 1,
                                                 75 => 1 })).to eq('Invalid coin denomination in payment: [25, 75]')
          end

          it 'returns an error message for mixed valid and invalid denominations' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke',
                                               { 100 => 1,
                                                 25 => 1 })).to eq('Invalid coin denomination in payment: [25]')
          end
        end

        # context 'change given in valid amount type' do
        # end check the coins specified are valid
      end
    end
  end
end
