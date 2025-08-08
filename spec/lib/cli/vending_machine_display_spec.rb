require 'spec_helper'
require_relative '../../../lib/cli/vending_machine_display'
require_relative '../../../lib/cli/currency_formatter'

RSpec.describe VendingMachineDisplay do
  let(:vending_machine) { double('VendingMachine') }
  let(:currency_formatter) { double('CurrencyFormatter') }
  let(:display) { described_class.new(vending_machine, currency_formatter) }

  let(:coke_item) { double('Item', name: 'Coke', quantity: 5) }
  let(:chips_item) { double('Item', name: 'Chips', quantity: 3) }
  let(:items) { [coke_item, chips_item] }

  describe '#show_welcome_message' do
    it 'displays welcome header and message' do
      expected_output = "=== Vending Machine CLI ===\nWelcome! What would you like to purchase through the Vending machine?\n\n"
      expect { display.show_welcome_message }.to output(expected_output).to_stdout
    end
  end

  describe '#show_menu_options' do
    it 'displays all menu options with prompt' do
      expected_output = [
        'Choose an option:',
        '1. Display available items',
        '2. Purchase item with session',
        '3. Display current balance',
        '4. Display machine status',
        '5. Reload or add new items',
        '6. Reload change',
        'q. Quit',
        'Enter your choice: '
      ].join("\n")

      expect { display.show_menu_options }.to output(expected_output).to_stdout
    end
  end

  describe '#show_available_items' do
    it 'displays items with formatted prices and quantities' do
      allow(vending_machine).to receive(:items).and_return(items)
      allow(currency_formatter).to receive(:format_item_price).with(coke_item).and_return('€1.50')
      allow(currency_formatter).to receive(:format_item_price).with(chips_item).and_return('€1.00')

      expected_output = [
        "\n=== Available Items in the Vending Machine ===",
        '1. Coke - €1.50 (5 available)',
        "2. Chips - €1.00 (3 available)\n"
      ].join("\n")

      expect { display.show_available_items }.to output(expected_output).to_stdout
    end

    it 'handles empty items list' do
      allow(vending_machine).to receive(:items).and_return([])

      expected_output = "\n=== Available Items in the Vending Machine ===\n"
      expect { display.show_available_items }.to output(expected_output).to_stdout
    end
  end

  describe '#show_current_balance' do
    it 'displays balance with formatted currency and coin details' do
      allow(vending_machine).to receive(:available_change).and_return(850)
      allow(vending_machine).to receive(:balance_in_english).and_return('2x €2, 1x €1, 6x 50c')
      allow(currency_formatter).to receive(:format_amount).with(850).and_return('€8.50')

      expected_output = [
        "\n=== Current Balance ===",
        'Available change: €8.50',
        "Coins: 2x €2, 1x €1, 6x 50c\n"
      ].join("\n")

      expect { display.show_current_balance }.to output(expected_output).to_stdout
    end
  end

  describe '#show_change_return_info' do
    it 'displays change return information with current machine balance' do
      allow(vending_machine).to receive(:available_change).and_return(850)
      allow(vending_machine).to receive(:balance_in_english).and_return('2x €2, 1x €1, 6x 50c')
      allow(currency_formatter).to receive(:format_amount).with(850).and_return('€8.50')

      expected_output = [
        "\n=== Return Change ===",
        'Note: Change is automatically returned after each purchase.',
        'Available change in machine: €8.50',
        "Coins: 2x €2, 1x €1, 6x 50c\n"
      ].join("\n")

      expect { display.show_change_return_info }.to output(expected_output).to_stdout
    end
  end

  describe '#show_machine_status' do
    it 'displays complete machine status including balance and inventory' do
      allow(vending_machine).to receive(:available_change).and_return(850)
      allow(vending_machine).to receive(:balance_in_english).and_return('2x €2, 1x €1, 6x 50c')
      allow(vending_machine).to receive(:items).and_return(items)
      allow(currency_formatter).to receive(:format_amount).with(850).and_return('€8.50')

      expected_output = [
        "\n=== Machine Status ===",
        'Available change: €8.50',
        'Coins: 2x €2, 1x €1, 6x 50c',
        '',
        'Items in stock:',
        '  Coke: 5 units',
        "  Chips: 3 units\n"
      ].join("\n")

      expect { display.show_machine_status }.to output(expected_output).to_stdout
    end
  end

  describe '#show_payment_instructions' do
    it 'displays payment format instructions' do
      expected_output = [
        'Format: Enter payment as a hash of coin denominations in cents',
        'Example: {100 => 2, 25 => 1} means 2, 1 Euro coins(100 cents is 1 Euro) + 1 quarter = $2.25',
        'Available denominations: 1, 2, 5, 10, 20, 50, 100, 200 cents'
      ].join("\n") + "\n"

      expect { display.show_payment_instructions }.to output(expected_output).to_stdout
    end
  end

  describe '#show_goodbye_message' do
    it 'displays goodbye message' do
      expect { display.show_goodbye_message }.to output("Goodbye!\n").to_stdout
    end
  end

  describe '#show_invalid_choice_message' do
    it 'displays invalid choice message' do
      expect { display.show_invalid_choice_message }.to output("Invalid choice. Please try again.\n").to_stdout
    end
  end
end
