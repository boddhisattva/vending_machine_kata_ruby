
RSpec.describe CurrencyFormatter do
  let(:formatter) { described_class.new }

  describe '#format_amount' do
    it 'formats amount in cents to euro currency format' do
      expect(formatter.format_amount(150)).to eq('€1.50')
      expect(formatter.format_amount(100)).to eq('€1.00')
      expect(formatter.format_amount(75)).to eq('€0.75')
      expect(formatter.format_amount(0)).to eq('€0.00')
    end
  end

  describe '#format_item_price' do
    it 'formats item price using format_amount' do
      item = Item.new('Coke', 150, 5)
      expect(formatter.format_item_price(item)).to eq('€1.50')
    end
  end
end
