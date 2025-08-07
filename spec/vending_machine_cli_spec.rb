# frozen_string_literal: true

require_relative '../bin/vending_machine_cli'

describe VendingMachineCLI do
  let(:cli) { VendingMachineCLI.new }

  before do
    allow($stdout).to receive(:write)  # Suppress output during tests
    allow(cli).to receive(:puts)       # Suppress puts output
    allow(cli).to receive(:print)      # Suppress print output
  end

  describe 'end-to-end purchase scenarios' do
    describe 'multiple purchases in same session' do
      context 'when user makes consecutive successful purchases' do
        it 'allows multiple purchases one after another' do
          # Mock user inputs for first purchase: item selection, payment
          allow(cli).to receive(:safe_gets).and_return(
            '1', # Select Coke (€1.50)
            '{200 => 1}', # Pay €2.00 (exact change returned)
            '2', # Select Chips (€1.00) for second purchase
            '{100 => 1}', # Pay €1.00 (exact amount)
            nil # End input
          )

          # Start first purchase
          expect { cli.send(:purchase_with_session) }.not_to raise_error

          # Start second purchase
          expect { cli.send(:purchase_with_session) }.not_to raise_error

          # Verify both items' quantities decreased
          coke_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Coke' }
          chips_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Chips' }

          expect(coke_item.quantity).to eq(4)   # Started with 5, bought 1
          expect(chips_item.quantity).to eq(2)  # Started with 3, bought 1
        end

        it 'maintains machine balance correctly across multiple purchases' do
          initial_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount

          allow(cli).to receive(:safe_gets).and_return(
            '3',           # Select Candy (€0.75)
            '{100 => 1}',  # Pay €1.00 (€0.25 change)
            '4',           # Select Water (€1.25)
            '{200 => 1}',  # Pay €2.00 (€0.75 change)
            nil
          )

          # First purchase
          cli.send(:purchase_with_session)
          # Second purchase
          cli.send(:purchase_with_session)

          # Total money received: €1.00 + €2.00 = €3.00
          # Total change given: €0.25 + €0.75 = €1.00
          # Net increase: €2.00 = 200 cents
          expected_balance = initial_balance + 200

          final_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount
          expect(final_balance).to eq(expected_balance)
        end
      end

      context 'when user makes mixed successful and cancelled purchases' do
        it 'handles purchase cancellation without affecting subsequent purchases' do
          allow(cli).to receive(:safe_gets).and_return(
            '1',         # Select Coke
            'cancel',    # Cancel first purchase
            '2',         # Select Chips for second purchase
            '{100 => 1}', # Pay €1.00 for Chips
            nil
          )

          # First purchase (cancelled)
          cli.send(:purchase_with_session)
          # Second purchase (completed)
          cli.send(:purchase_with_session)

          # Verify only Chips quantity decreased
          coke_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Coke' }
          chips_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Chips' }

          expect(coke_item.quantity).to eq(5)   # Unchanged due to cancellation
          expect(chips_item.quantity).to eq(2)  # Decreased by 1
        end
      end
    end

    describe 'incorrect amount handling' do
      context 'when user provides invalid payment format' do
        it 'prompts for correct format and allows purchase to complete' do
          allow(cli).to receive(:safe_gets).and_return(
            '1',              # Select Coke (€1.50)
            'invalid input',  # Invalid payment format
            'not a hash',     # Another invalid format
            '{abc => 2}',     # Invalid denomination format
            '{200 => 1}',     # Valid payment (€2.00)
            nil
          )

          expect { cli.send(:purchase_with_session) }.not_to raise_error

          # Verify purchase completed despite initial invalid inputs
          coke_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Coke' }
          expect(coke_item.quantity).to eq(4) # Purchase successful
        end

        it 'handles empty and malformed hash inputs gracefully' do
          allow(cli).to receive(:safe_gets).and_return(
            '2',              # Select Chips (€1.00)
            '{}',             # Empty hash
            '{100 => }',      # Missing value
            '{=> 2}',         # Missing key
            '{100 => 0}',     # Zero count (invalid)
            '{100 => 1}',     # Valid payment
            nil
          )

          expect { cli.send(:purchase_with_session) }.not_to raise_error

          chips_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Chips' }
          expect(chips_item.quantity).to eq(2) # Purchase successful
        end

        it 'rejects invalid coin denominations and allows retry' do
          allow(cli).to receive(:safe_gets).and_return(
            '3',              # Select Candy (€0.75)
            '{15 => 5}',      # Invalid denomination (15 cents doesn't exist)
            '{3 => 10}',      # Invalid denomination (3 cents doesn't exist)
            '{100 => 1}',     # Valid payment
            nil
          )

          # Mock the vending machine to verify invalid denominations are caught
          vending_machine = cli.instance_variable_get(:@vending_machine)
          expect(vending_machine).to receive(:insert_payment).with({ 15 => 5 }).and_return('Invalid denominations provided')
          expect(vending_machine).to receive(:insert_payment).with({ 3 => 10 }).and_return('Invalid denominations provided')
          expect(vending_machine).to receive(:insert_payment).with({ 100 => 1 }).and_call_original

          expect { cli.send(:purchase_with_session) }.not_to raise_error
        end
      end
    end

    describe 'insufficient amount handling' do
      context 'when user provides insufficient money initially' do
        it 'prompts for more money and completes purchase' do
          allow(cli).to receive(:safe_gets).and_return(
            '1',           # Select Coke (€1.50 = 150 cents)
            '{50 => 1}',   # Pay 50 cents (insufficient)
            '{100 => 1}',  # Pay additional €1.00 (total €1.50, exact amount)
            nil
          )

          expect { cli.send(:purchase_with_session) }.not_to raise_error

          coke_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Coke' }
          expect(coke_item.quantity).to eq(4) # Purchase successful
        end

        it 'handles multiple insufficient payments until sufficient amount' do
          allow(cli).to receive(:safe_gets).and_return(
            '4',           # Select Water (€1.25 = 125 cents)
            '{20 => 1}',   # Pay 20 cents
            '{20 => 1}',   # Pay another 20 cents (total 40 cents)
            '{50 => 1}',   # Pay 50 cents (total 90 cents)
            '{50 => 1}',   # Pay another 50 cents (total 140 cents, sufficient)
            nil
          )

          expect { cli.send(:purchase_with_session) }.not_to raise_error

          water_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Water' }
          expect(water_item.quantity).to eq(1) # Purchase successful
        end

        it 'tracks accumulated payment correctly' do
          vending_machine = cli.instance_variable_get(:@vending_machine)

          allow(cli).to receive(:safe_gets).and_return(
            '2',           # Select Chips (€1.00 = 100 cents)
            '{20 => 2}',   # Pay 40 cents
            '{10 => 3}',   # Pay 30 cents (total 70 cents)
            '{50 => 1}',   # Pay 50 cents (total 120 cents, overpaid by 20 cents)
            nil
          )

          # Mock the session manager to verify payment accumulation
          session_manager = vending_machine.instance_variable_get(:@session_manager)
          expect(session_manager).to receive(:add_payment).exactly(3).times.and_call_original

          expect { cli.send(:purchase_with_session) }.not_to raise_error

          chips_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Chips' }
          expect(chips_item.quantity).to eq(2) # Purchase successful
        end
      end

      context 'when user cancels after insufficient payments' do
        it 'returns accumulated money and cancels purchase' do
          initial_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount

          allow(cli).to receive(:safe_gets).and_return(
            '1',           # Select Coke (€1.50)
            '{50 => 2}',   # Pay €1.00 (insufficient)
            'cancel',      # Cancel purchase
            nil
          )

          expect { cli.send(:purchase_with_session) }.not_to raise_error

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

          allow(cli).to receive(:safe_gets).and_return(
            '3',           # Select Candy (€0.75 = 75 cents)
            '{200 => 1}',  # Pay €2.00 (overpaid by €1.25 = 125 cents)
            nil
          )

          expect { cli.send(:purchase_with_session) }.not_to raise_error

          # Net change in balance: +200 cents (received) - 125 cents (change given) = +75 cents
          expected_balance = initial_balance + 75
          final_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount
          expect(final_balance).to eq(expected_balance)

          candy_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Candy' }
          expect(candy_item.quantity).to eq(7) # Purchase successful
        end

        it 'handles large overpayments with complex change combinations' do
          allow(cli).to receive(:safe_gets).and_return(
            '2',                      # Select Chips (€1.00 = 100 cents)
            '{200 => 2, 100 => 1}',   # Pay €5.00 (overpaid by €4.00 = 400 cents)
            nil
          )

          expect { cli.send(:purchase_with_session) }.not_to raise_error

          chips_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Chips' }
          expect(chips_item.quantity).to eq(2) # Purchase successful
        end

        it 'maintains correct change inventory after multiple overpayments' do
          initial_balance = cli.instance_variable_get(:@vending_machine).balance.amount.dup

          allow(cli).to receive(:safe_gets).and_return(
            '4',           # Select Water (€1.25)
            '{200 => 1}',  # Pay €2.00 (€0.75 change)
            '1',           # Select Coke (€1.50)
            '{200 => 1}',  # Pay €2.00 (€0.50 change)
            nil
          )

          # First purchase
          cli.send(:purchase_with_session)
          # Second purchase
          cli.send(:purchase_with_session)

          # Verify change denominations are properly managed
          final_balance = cli.instance_variable_get(:@vending_machine).balance.amount

          # Total money in: €4.00 = 400 cents
          # Total change out: €1.25 = 125 cents
          # Net increase: 275 cents
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

          allow(cli).to receive(:safe_gets).and_return(
            '1',           # Select Test Item (€0.50)
            '{200 => 1}',  # Pay €2.00 (need €1.50 change, but can't make it)
            nil
          )

          # This should handle the insufficient change scenario
          expect { cli.send(:purchase_with_session) }.not_to raise_error
        end
      end
    end

    describe 'edge cases and error handling' do
      context 'when selecting invalid item numbers' do
        it 'handles invalid item selection gracefully' do
          allow(cli).to receive(:safe_gets).and_return(
            '99',          # Invalid item number
            '-1',          # Negative item number
            'abc',         # Non-numeric input
            '1',           # Valid item selection
            '{200 => 1}',  # Valid payment
            nil
          )

          # Should handle invalid selections and eventually complete valid purchase
          expect do
            cli.send(:purchase_with_session)  # Invalid selection
            cli.send(:purchase_with_session)  # Invalid selection
            cli.send(:purchase_with_session)  # Invalid selection
            cli.send(:purchase_with_session)  # Valid purchase
          end.not_to raise_error
        end
      end

      context 'when items are out of stock' do
        it 'handles out of stock scenarios' do
          # Deplete Coke inventory
          coke_item = cli.instance_variable_get(:@vending_machine).items.find { |item| item.name == 'Coke' }
          coke_item.instance_variable_set(:@quantity, 0)

          allow(cli).to receive(:safe_gets).and_return(
            '1', # Select Coke (out of stock)
            nil
          )

          expect { cli.send(:purchase_with_session) }.not_to raise_error

          # Verify inventory remains at 0
          expect(coke_item.quantity).to eq(0)
        end
      end

      context 'when input stream ends unexpectedly' do
        it 'handles nil input gracefully' do
          allow(cli).to receive(:safe_gets).and_return(nil)

          expect { cli.send(:purchase_with_session) }.not_to raise_error
        end
      end
    end
  end
end
