describe VendingMachine do
  describe '#initialize' do
    context 'given a set of items & balance' do
      let(:items) { [Item.new('Coke', 150), Item.new('Pepsi', 175)] }
      let(:balance) { Change.new(Money.new(200, 'GBP')) }

      it 'returns the items & balance' do
        vending_machine = VendingMachine.new(items, balance)
        expect(vending_machine.items).to eq(items)
        expect(vending_machine.balance).to eq(balance)
      end
    end
  end
end
