describe VendingMachine do
  let(:items) { [Item.new('Coke', 150, 1), Item.new('Pepsi', 175, 1)] }
  let(:balance) { Change.new(Money.new(1072, 'GBP')) }

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
                                               200)).to eq("Thank you for your purchase of #{selected_item.name}. Please collect your item and change: 50")
          end
        end

        context 'when the user pays the exact amount' do
          it 'returns the item & balance' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke',
                                               150)).to eq("Thank you for your purchase of #{selected_item.name}. Please collect your item.")
          end
        end

        context 'when the user pays less than the item price' do
          it 'clearly specifies the remaining amount pending' do
            vending_machine = VendingMachine.new(items, balance)
            expect(vending_machine.select_item('Coke',
                                               100)).to eq('You need to pay 50 more cents to purchase Coke')
          end
        end

        # context 'when the quantity of the item is 0' do
        # end

        # context 'change given in valid amount type' do
        # end check the coins specified are valid
      end
    end
  end
end
