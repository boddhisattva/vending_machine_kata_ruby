require 'spec_helper'
require_relative '../../../lib/cli/item_selector'

RSpec.describe ItemSelector do
  let(:vending_machine) { double('VendingMachine') }
  let(:currency_formatter) { double('CurrencyFormatter') }
  let(:selector) { described_class.new(vending_machine, currency_formatter) }

  let(:coke_item) { double('Item', name: 'Coke', price: 150) }
  let(:chips_item) { double('Item', name: 'Chips', price: 100) }
  let(:candy_item) { double('Item', name: 'Candy', price: 75) }
  let(:items) { [coke_item, chips_item, candy_item] }

  describe '#select_item_for_purchase' do
    before do
      allow(vending_machine).to receive(:items).and_return(items)
    end

    context 'with valid item number' do
      it 'returns first item and shows details when selecting item 1' do
        allow(currency_formatter).to receive(:format_item_price).with(coke_item).and_return('€1.50')

        expected_output = "Selected: Coke - €1.50\n\n"
        expect { selector.select_item_for_purchase(1) }.to output(expected_output).to_stdout

        result = selector.select_item_for_purchase(1)
        expect(result).to eq(coke_item)
      end

      it 'returns second item and shows details when selecting item 2' do
        allow(currency_formatter).to receive(:format_item_price).with(chips_item).and_return('€1.00')

        expected_output = "Selected: Chips - €1.00\n\n"
        expect { selector.select_item_for_purchase(2) }.to output(expected_output).to_stdout

        result = selector.select_item_for_purchase(2)
        expect(result).to eq(chips_item)
      end

      it 'returns third item and shows details when selecting item 3' do
        allow(currency_formatter).to receive(:format_item_price).with(candy_item).and_return('€0.75')

        expected_output = "Selected: Candy - €0.75\n\n"
        expect { selector.select_item_for_purchase(3) }.to output(expected_output).to_stdout

        result = selector.select_item_for_purchase(3)
        expect(result).to eq(candy_item)
      end
    end

    context 'with invalid item numbers' do
      it 'returns nil and shows error for item number 0' do
        expect { selector.select_item_for_purchase(0) }.to output("Invalid item number.\n").to_stdout
        expect(selector.select_item_for_purchase(0)).to be_nil
      end

      it 'returns nil and shows error for negative item number' do
        expect { selector.select_item_for_purchase(-1) }.to output("Invalid item number.\n").to_stdout
        expect(selector.select_item_for_purchase(-1)).to be_nil
      end

      it 'returns nil and shows error for item number beyond available items' do
        expect { selector.select_item_for_purchase(4) }.to output("Invalid item number.\n").to_stdout
        expect(selector.select_item_for_purchase(4)).to be_nil

        expect { selector.select_item_for_purchase(10) }.to output("Invalid item number.\n").to_stdout
        expect(selector.select_item_for_purchase(10)).to be_nil
      end
    end

    context 'with empty items list' do
      it 'returns nil and shows error when no items available' do
        allow(vending_machine).to receive(:items).and_return([])

        expect { selector.select_item_for_purchase(1) }.to output("Invalid item number.\n").to_stdout
        expect(selector.select_item_for_purchase(1)).to be_nil
      end
    end

    context 'integration with currency formatter' do
      it 'uses currency formatter to display item price' do
        expect(currency_formatter).to receive(:format_item_price).with(coke_item).and_return('€1.50')

        selector.select_item_for_purchase(1)
      end
    end
  end
end
