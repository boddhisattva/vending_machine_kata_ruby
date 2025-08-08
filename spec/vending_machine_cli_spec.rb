# frozen_string_literal: true

require_relative '../bin/vending_machine_cli'
require_relative '../lib/cli/payment_input_parser'

describe VendingMachineCLI do
  let(:cli) { VendingMachineCLI.new }
  let(:payment_parser) { PaymentInputParser.new }

  before do
    allow($stdout).to receive(:write)  # Suppress output during tests
    allow(cli).to receive(:puts)       # Suppress puts output
    allow(cli).to receive(:print)      # Suppress print output
  end

  describe 'end-to-end purchase scenarios' do
    # Helper method to simulate a purchase session
    def simulate_purchase_session(cli, item_number, *payment_inputs, payment_parser: PaymentInputParser.new)
      vending_machine = cli.instance_variable_get(:@vending_machine)

      # Select item
      items = vending_machine.items
      return if item_number < 1 || item_number > items.length

      item = items[item_number - 1]
      vending_machine.start_purchase(item.name)

      # Process payments
      payment_inputs.each do |input|
        if input == 'cancel'
          vending_machine.cancel_purchase
          break
        elsif input.nil?
          break
        else
          # Parse payment hash string safely
          payment = payment_parser.parse(input)
          next unless payment.is_a?(Hash)

          result = vending_machine.insert_payment(payment)
          break if result.include?('Payment complete') || result.include?('Thank you for your purchase')
        end
      end
    end

    describe 'insufficient amount handling' do
      context 'when user provides insufficient money initially' do
        it 'prompts for more money and completes purchase' do
          simulate_purchase_session(cli, 1, '{50 => 1}', '{100 => 1}')

          coke_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Coke' }
          expect(coke_item.quantity).to eq(4) # Purchase successful
        end

        it 'handles multiple insufficient payments until sufficient amount' do
          simulate_purchase_session(cli, 4, '{20 => 1}', '{20 => 1}', '{50 => 1}', '{50 => 1}')

          water_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Water' }
          expect(water_item.quantity).to eq(1) # Purchase successful
        end

        it 'tracks accumulated payment correctly' do
          vending_machine = cli.instance_variable_get(:@vending_machine)

          # Mock the session manager to verify payment accumulation
          session_manager = vending_machine.instance_variable_get(:@session_manager)
          expect(session_manager).to receive(:add_payment).exactly(3).times.and_call_original

          simulate_purchase_session(cli, 2, '{20 => 2}', '{10 => 3}', '{50 => 1}')

          chips_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Chips' }
          expect(chips_item.quantity).to eq(2) # Purchase successful
        end
      end

      context 'when user cancels after insufficient payments' do
        it 'returns accumulated money and cancels purchase' do
          initial_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount

          simulate_purchase_session(cli, 1, '{50 => 2}', 'cancel')

          # Balance should remain unchanged since purchase was cancelled
          final_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount
          expect(final_balance).to eq(initial_balance)

          # Item quantity should remain unchanged
          coke_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Coke' }
          expect(coke_item.quantity).to eq(5) # Unchanged
        end
      end
    end

    describe 'excessive money handling' do
      context 'when user overpays for items' do
        it 'returns appropriate change for single overpayment' do
          initial_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount

          simulate_purchase_session(cli, 3, '{200 => 1}')

          # Net change in balance: +200 cents (received) - 125 cents (change given) = +75 cents
          expected_balance = initial_balance + 75
          final_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount
          expect(final_balance).to eq(expected_balance)

          candy_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Candy' }
          expect(candy_item.quantity).to eq(7) # Purchase successful
        end

        it 'handles large overpayments with complex change combinations' do
          simulate_purchase_session(cli, 2, '{200 => 2, 100 => 1}')

          chips_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Chips' }
          expect(chips_item.quantity).to eq(2) # Purchase successful
        end

        it 'maintains correct change inventory after multiple overpayments' do
          initial_balance = cli.instance_variable_get(:@vending_machine).balance.amount.dup

          # First purchase
          simulate_purchase_session(cli, 4, '{200 => 1}')
          # Second purchase
          simulate_purchase_session(cli, 1, '{200 => 1}')

          # Verify change denominations are properly managed
          final_balance = cli.instance_variable_get(:@vending_machine).balance.amount

          # Total money in: €4.00 = 400 cents
          # Total change out: €1.25 = 125 cents
          expected_total = initial_balance.sum { |denom, count| denom * count } + 275
          actual_total = final_balance.sum { |denom, count| denom * count }

          expect(actual_total).to eq(expected_total)
        end
      end

      context 'when change cannot be made due to insufficient denominations' do
        it 'handles insufficient change scenario appropriately' do
          # Create a machine with very limited change
          limited_balance = {
            200 => 1,  # Only one €2 coin
            100 => 0,  # No €1 coins
            50 => 0,   # No 50c coins
            20 => 0,   # No smaller denominations
            10 => 0,
            5 => 0,
            2 => 0,
            1 => 0
          }

          items = [Item.new('Test Item', 50, 1)] # €0.50 item
          vending_machine = VendingMachine.new(items, Change.new(limited_balance))
          cli.instance_variable_set(:@vending_machine, vending_machine)

          # This should handle the insufficient change scenario
          expect { simulate_purchase_session(cli, 1, '{200 => 1}') }.not_to raise_error
        end
      end
    end
  end
end
