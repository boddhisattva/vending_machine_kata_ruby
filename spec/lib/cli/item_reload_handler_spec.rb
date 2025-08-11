
RSpec.describe ItemReloadHandler do
  let(:vending_machine) { double('VendingMachine') }
  let(:display) { double('VendingMachineDisplay') }
  let(:input_handler) { double('UserInputHandler') }
  let(:reloader) { described_class.new(vending_machine, display, input_handler) }

  describe '#load_items_for_machine' do
    before do
      allow(vending_machine).to receive(:display_stock).and_return('Coke: 5 units @ €1.50 each')
      allow(vending_machine).to receive(:items).and_return([
                                                             double('Item', name: 'Coke', quantity: 5)
                                                           ])
    end

    context 'when reloading existing item' do
      it 'adds quantity to existing item' do
        allow(input_handler).to receive(:safe_gets).and_return('Coke', '3')
        allow(vending_machine).to receive(:load_item).with('Coke', 3)
                                                       .and_return('Successfully added 3 units to Coke. New quantity: 8')

        expected_output = [
          "\n=== Reload or Add New Items ===",
          'Current stock:',
          'Coke: 5 units @ €1.50 each',
          '',
          "Enter item name: Enter quantity to add: Successfully added 3 units to Coke. New quantity: 8\n"
        ].join("\n")

        expect { reloader.load_items_for_machine }.to output(expected_output).to_stdout
      end

      it 'handles invalid quantity gracefully' do
        allow(input_handler).to receive(:safe_gets).and_return('Coke', '0')
        allow(vending_machine).to receive(:load_item).with('Coke', 0)
                                                       .and_return('Invalid quantity. Please provide a positive number.')

        expected_output = [
          "\n=== Reload or Add New Items ===",
          'Current stock:',
          'Coke: 5 units @ €1.50 each',
          '',
          "Enter item name: Enter quantity to add: Invalid quantity. Please provide a positive number.\n"
        ].join("\n")

        expect { reloader.load_items_for_machine }.to output(expected_output).to_stdout
      end
    end

    context 'when adding new item' do
      it 'asks for price and adds new item' do
        allow(vending_machine).to receive(:items).and_return([])
        allow(input_handler).to receive(:safe_gets).and_return('Pepsi', '5', '175')
        allow(vending_machine).to receive(:load_item).with('Pepsi', 5, 175)
                                                       .and_return('Successfully added new item: Pepsi - €1.75 (5 units)')

        expected_output = [
          "\n=== Reload or Add New Items ===",
          'Current stock:',
          'Coke: 5 units @ €1.50 each',
          '',
          "Enter item name: Enter quantity to add: New item detected. Enter price in cents (e.g., 150 for €1.50): Successfully added new item: Pepsi - €1.75 (5 units)\n"
        ].join("\n")

        expect { reloader.load_items_for_machine }.to output(expected_output).to_stdout
      end

      it 'handles invalid price gracefully' do
        allow(vending_machine).to receive(:items).and_return([])
        allow(input_handler).to receive(:safe_gets).and_return('Pepsi', '5', '-100')
        allow(vending_machine).to receive(:load_item).with('Pepsi', 5, -100)
                                                       .and_return('Invalid price. Please provide a positive number.')

        expected_output = [
          "\n=== Reload or Add New Items ===",
          'Current stock:',
          'Coke: 5 units @ €1.50 each',
          '',
          "Enter item name: Enter quantity to add: New item detected. Enter price in cents (e.g., 150 for €1.50): Invalid price. Please provide a positive number.\n"
        ].join("\n")

        expect { reloader.load_items_for_machine }.to output(expected_output).to_stdout
      end
    end

    context 'when user cancels' do
      it 'handles nil input gracefully' do
        allow(input_handler).to receive(:safe_gets).and_return(nil)

        expected_output = [
          "\n=== Reload or Add New Items ===",
          'Current stock:',
          'Coke: 5 units @ €1.50 each',
          '',
          'Enter item name: '
        ].join("\n")

        expect { reloader.load_items_for_machine }.to output(expected_output).to_stdout
      end
    end
  end
end
