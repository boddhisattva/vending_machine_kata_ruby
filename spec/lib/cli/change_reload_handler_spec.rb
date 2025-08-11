
RSpec.describe ChangeReloadHandler do
  let(:vending_machine) { double('VendingMachine') }
  let(:currency_formatter) { double('CurrencyFormatter') }
  let(:payment_parser) { double('PaymentInputParser') }
  let(:input_handler) { double('UserInputHandler') }
  let(:reloader) { described_class.new(vending_machine, currency_formatter, payment_parser, input_handler) }

  describe '#reload_change_for_machine' do
    before do
      allow(vending_machine).to receive(:available_change).and_return(1072)
      allow(vending_machine).to receive(:balance_in_english).and_return('2x €2, 1x €1, 6x 50c')
      allow(currency_formatter).to receive(:format_amount).with(1072).and_return('€10.72')
    end

    context 'when adding valid coins' do
      it 'successfully adds coins to machine' do
        allow(input_handler).to receive(:safe_gets).and_return('{100 => 2, 50 => 3}')
        allow(payment_parser).to receive(:parse).with('{100 => 2, 50 => 3}')
                                                .and_return({ 100 => 2, 50 => 3 })
        allow(vending_machine).to receive(:reload_change).with({ 100 => 2, 50 => 3 })
                                                         .and_return('Successfully added coins: 2 €1 coins, 3 50-cent coins. Total balance: €14.22')

        expected_output = [
          "\n=== Reload Change ===",
          'Current balance: €10.72',
          'Coins: 2x €2, 1x €1, 6x 50c',
          '',
          'Format: Enter coins as a hash of denominations in cents',
          'Example: {100 => 5, 50 => 10} means 5 €1 coins and 10 50-cent coins',
          'Available denominations: 1 cent, 2 cent, 5 cent, 10 cent, 20 cent, 50 cent, €1, €2 coins',
          "Enter coins to add: Successfully added coins: 2 €1 coins, 3 50-cent coins. Total balance: €14.22\n"
        ].join("\n")

        expect { reloader.reload_change_for_machine }.to output(expected_output).to_stdout
      end

      it 'handles empty coin hash' do
        allow(input_handler).to receive(:safe_gets).and_return('{}')
        allow(payment_parser).to receive(:parse).with('{}').and_return({})
        allow(vending_machine).to receive(:reload_change).with({})
                                                         .and_return('Successfully added coins: No coins. Total balance: €10.72')

        expected_output = [
          "\n=== Reload Change ===",
          'Current balance: €10.72',
          'Coins: 2x €2, 1x €1, 6x 50c',
          '',
          'Format: Enter coins as a hash of denominations in cents',
          'Example: {100 => 5, 50 => 10} means 5 €1 coins and 10 50-cent coins',
          'Available denominations: 1 cent, 2 cent, 5 cent, 10 cent, 20 cent, 50 cent, €1, €2 coins',
          "Enter coins to add: Successfully added coins: No coins. Total balance: €10.72\n"
        ].join("\n")

        expect { reloader.reload_change_for_machine }.to output(expected_output).to_stdout
      end
    end

    context 'when input is invalid' do
      it 'shows error for invalid format' do
        allow(input_handler).to receive(:safe_gets).and_return('invalid input')
        allow(payment_parser).to receive(:parse).with('invalid input').and_return(nil)

        expected_output = [
          "\n=== Reload Change ===",
          'Current balance: €10.72',
          'Coins: 2x €2, 1x €1, 6x 50c',
          '',
          'Format: Enter coins as a hash of denominations in cents',
          'Example: {100 => 5, 50 => 10} means 5 €1 coins and 10 50-cent coins',
          'Available denominations: 1 cent, 2 cent, 5 cent, 10 cent, 20 cent, 50 cent, €1, €2 coins',
          "Enter coins to add: Invalid format. Please use a hash format like {100 => 5, 50 => 10}\n"
        ].join("\n")

        expect { reloader.reload_change_for_machine }.to output(expected_output).to_stdout
      end
    end

    context 'when user cancels' do
      it 'handles nil input gracefully' do
        allow(input_handler).to receive(:safe_gets).and_return(nil)

        expected_output = [
          "\n=== Reload Change ===",
          'Current balance: €10.72',
          'Coins: 2x €2, 1x €1, 6x 50c',
          '',
          'Format: Enter coins as a hash of denominations in cents',
          'Example: {100 => 5, 50 => 10} means 5 €1 coins and 10 50-cent coins',
          'Available denominations: 1 cent, 2 cent, 5 cent, 10 cent, 20 cent, 50 cent, €1, €2 coins',
          'Enter coins to add: '
        ].join("\n")

        expect { reloader.reload_change_for_machine }.to output(expected_output).to_stdout
      end
    end
  end
end
