require 'vending_machine'

describe VendingMachine do
  describe '#initialize' do
    context 'give a set of items & balance' do
      let(:items) { %w[Coke Pepsi Soda] }
      let(:balance) { 10.72 }

      it 'returns the item & balance' do
        vending_machine = VendingMachine.new(items, balance)
        expect(vending_machine.items).to eq(items)
        expect(vending_machine.balance).to eq(balance)
      end
    end
  end
end
