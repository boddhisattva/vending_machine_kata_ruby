
RSpec.describe VendingMachineInitializer do
  let(:initializer) { described_class.new }
  let(:vending_machine) { initializer.initialize_vending_machine }

  describe '#initialize_vending_machine' do
    it 'creates vending machine with initial items and balance' do
      expect(vending_machine).to be_a(VendingMachine)
      expect(vending_machine.items.size).to eq(4)
      expect(vending_machine.balance).to be_a(Change)
    end

    it 'creates items with correct properties' do
      items = vending_machine.items

      coke = items.find { |item| item.name == 'Coke' }
      expect(coke.price).to eq(150)
      expect(coke.quantity).to eq(5)

      chips = items.find { |item| item.name == 'Chips' }
      expect(chips.price).to eq(100)
      expect(chips.quantity).to eq(3)

      candy = items.find { |item| item.name == 'Candy' }
      expect(candy.price).to eq(75)
      expect(candy.quantity).to eq(8)

      water = items.find { |item| item.name == 'Water' }
      expect(water.price).to eq(125)
      expect(water.quantity).to eq(2)
    end

    it 'creates balance with expected denomination counts' do
      # Test that balance has correct total: 1072 cents = €10.72
      expected_total = 1072
      expect(vending_machine.available_change).to eq(expected_total)
    end
  end

  describe 'constants' do
    it 'defines frozen initial balance hash' do
      expect(described_class::INITIAL_BALANCE).to be_frozen
      expect(described_class::INITIAL_BALANCE[50]).to eq(6)
      expect(described_class::INITIAL_BALANCE[100]).to eq(2)
    end

    it 'defines frozen initial items array' do
      expect(described_class::INITIAL_ITEMS).to be_frozen
      expect(described_class::INITIAL_ITEMS.size).to eq(4)
      expect(described_class::INITIAL_ITEMS.first[:name]).to eq('Coke')
    end
  end
end
