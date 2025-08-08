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
      # "Is the number less than 1?" (like 0 or negative numbers) || "Is the number bigger than how many items we have?"
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
      let(:vending_machine) { cli.instance_variable_get(:@vending_machine) }
      context 'when user provides insufficient money initially' do
        it 'prompts for more money and completes purchase' do
          coke_item = vending_machine.items.find { |item| item.name == 'Coke' }
          # Initial quantity of Coke before purchase
          expect(coke_item.quantity).to eq(5)

          # Initial balance
          initial_balance = vending_machine.balance.calculate_total_amount

          # Start purchase and make first insufficient payment
          vending_machine.start_purchase('Coke')
          result = vending_machine.insert_payment({ 50 => 1 })

          # Verify the prompt shows exactly how much more is needed
          expect(result).to eq('Please insert 100 more cents')

          # Complete the purchase with remaining amount
          final_result = vending_machine.insert_payment({ 100 => 1 })
          expect(final_result).to include('Thank you for your purchase')

          # Purchase successful, Coke quantity decreased by 1
          expect(coke_item.quantity).to eq(4)
        end

        it 'handles multiple insufficient payments until sufficient amount' do
          water_item = vending_machine.items.find { |item| item.name == 'Water' }
          # Initial quantity of Water before purchase
          expect(water_item.quantity).to eq(2)
          simulate_purchase_session(cli, 4, '{20 => 1}', '{20 => 1}', '{50 => 1}', '{50 => 1}')

          # Purchase successful, Water quantity decreased by 1
          expect(water_item.quantity).to eq(1)
        end
      end

      context 'when user cancels after insufficient payments' do
        it 'returns accumulated money and cancels purchase' do
          initial_balance = vending_machine.balance.calculate_total_amount
          coke_item = vending_machine.items.find { |item| item.name == 'Coke' }
          # Initial quantity of Coke before purchase
          expect(coke_item.quantity).to eq(5)

          simulate_purchase_session(cli, 1, '{50 => 2}', 'cancel')

          # Balance should remain unchanged since purchase was cancelled
          final_balance = cli.instance_variable_get(:@vending_machine).balance.calculate_total_amount
          expect(final_balance).to eq(initial_balance)

          # Item quantity should remain unchanged
          expect(coke_item.quantity).to eq(5)
        end
      end
    end

    describe 'exact payment handling' do
      context 'when user provides exact amount' do
        it 'completes purchase without change for Chips' do
          vending_machine = cli.instance_variable_get(:@vending_machine)
          chips_item = vending_machine.items.find { |item| item.name == 'Chips' }
          # Initial quantity of Chips before purchase
          expect(chips_item.quantity).to eq(3)

          # Start purchase for Chips (100 cents)
          vending_machine.start_purchase('Chips')

          # Pay with exact amount (100c = 100c)
          result = vending_machine.insert_payment({ 100 => 1 })

          # Verify the message only mentions item collection, no change
          expect(result).to eq('Thank you for your purchase of Chips. Please collect your item.')

          # Purchase successful, Chips quantity decreased by 1
          expect(chips_item.quantity).to eq(2)
        end
      end
    end

    describe 'purchase, reload, and status display' do
      it 'completes purchase, reloads item, and displays updated status' do
        vending_machine = cli.instance_variable_get(:@vending_machine)

        # Initial state - Chips has 3 units
        chips_item = vending_machine.items.find { |item| item.name == 'Chips' }
        expect(chips_item.quantity).to eq(3)

        # Step 1: Purchase Chips with exact payment
        vending_machine.start_purchase('Chips')
        purchase_result = vending_machine.insert_payment({ 100 => 1 })

        # Verify purchase message
        expect(purchase_result).to eq('Thank you for your purchase of Chips. Please collect your item.')

        # Verify quantity reduced to 2
        expect(chips_item.quantity).to eq(2)

        # Step 2: Reload Chips with 5 more units
        reload_result = vending_machine.reload_item('Chips', 5)

        # Verify reload message
        expect(reload_result).to eq('Successfully added 5 units to Chips. New quantity: 7')

        # Verify quantity is now 7
        expect(chips_item.quantity).to eq(7)

        # Step 3: Build status string to verify machine state
        status_lines = []
        status_lines << 'Items in stock:'
        vending_machine.items.each do |item|
          status_lines << "  #{item.name}: #{item.quantity} units"
        end
        status = status_lines.join("\n")

        # Verify status includes correct item quantities
        expect(status).to include('Items in stock:')
        expect(status).to include('Coke: 5 units')
        expect(status).to include('Chips: 7 units')
      end
    end

    describe 'add new item and purchase' do
      it 'displays status, adds new item, purchases it, and shows final status' do
        vending_machine = cli.instance_variable_get(:@vending_machine)

        # Step 1: Initial machine status check
        initial_balance_total = vending_machine.available_change
        initial_balance_english = vending_machine.balance_in_english

        expect(initial_balance_total).to eq(1072) # €10.72
        expect(initial_balance_english).to eq('1 2 Euro coin, 2 1 Euro coins, 6 50-cent coins, 10 20-cent coins, 10 10-cent coins, 10 5-cent coins, 10 2-cent coins, 2 1-cent coins')

        # Verify initial items
        initial_items = vending_machine.items.map { |item| "#{item.name}: #{item.quantity} units" }
        expect(initial_items).to include('Coke: 5 units')
        expect(initial_items).to include('Chips: 3 units')
        expect(initial_items).to include('Candy: 8 units')
        expect(initial_items).to include('Water: 2 units')
        expect(vending_machine.items.length).to eq(4)

        # Step 2: Reload with new item - Lindt Chocolate
        reload_result = vending_machine.reload_item('Lindt Chocolate', 5, 600)

        # Verify reload message for new item
        expect(reload_result).to eq('Successfully added new item: Lindt Chocolate - €6.00 (5 units)')

        # Step 3: Verify machine status after adding new item
        expect(vending_machine.items.length).to eq(5)
        lindt_item = vending_machine.items.find { |item| item.name == 'Lindt Chocolate' }
        expect(lindt_item).not_to be_nil
        expect(lindt_item.quantity).to eq(5)
        expect(lindt_item.price).to eq(600)

        updated_items = vending_machine.items.map { |item| "#{item.name}: #{item.quantity} units" }
        expect(updated_items).to include('Lindt Chocolate: 5 units')

        # Step 4: Purchase the newly added Lindt Chocolate with exact payment
        vending_machine.start_purchase('Lindt Chocolate')
        purchase_result = vending_machine.insert_payment({ 200 => 3 })

        # Verify purchase message
        expect(purchase_result).to eq('Thank you for your purchase of Lindt Chocolate. Please collect your item.')

        # Verify Lindt Chocolate quantity reduced to 4
        expect(lindt_item.quantity).to eq(4)

        # Step 5: Final machine status check
        final_balance_total = vending_machine.available_change
        final_balance_english = vending_machine.balance_in_english

        # Balance increased by 600 cents (3 x €2 coins added)
        expect(final_balance_total).to eq(1672) # €16.72 (10.72 + 6.00)
        # 3 more €2 coins added to initial balance
        expect(final_balance_english).to eq('4 2 Euro coins, 2 1 Euro coins, 6 50-cent coins, 10 20-cent coins, 10 10-cent coins, 10 5-cent coins, 10 2-cent coins, 2 1-cent coins')

        # Verify final items including the purchased Lindt Chocolate
        final_items = vending_machine.items.map { |item| "#{item.name}: #{item.quantity} units" }
        expect(final_items).to include('Coke: 5 units')
        expect(final_items).to include('Chips: 3 units')
        expect(final_items).to include('Candy: 8 units')
        expect(final_items).to include('Water: 2 units')
        expect(final_items).to include('Lindt Chocolate: 4 units')
      end
    end

    describe 'balance check, purchase with change, and reload change' do
      it 'checks balance, purchases with change, checks updated balance, and reloads change' do
        vending_machine = cli.instance_variable_get(:@vending_machine)

        # Step 1: Check initial balance
        initial_balance_total = vending_machine.available_change
        initial_balance_english = vending_machine.balance_in_english

        # Verify initial balance display format
        expect(initial_balance_total).to eq(1072) # €10.72 in cents
        expect(initial_balance_english).to eq('1 2 Euro coin, 2 1 Euro coins, 6 50-cent coins, 10 20-cent coins, 10 10-cent coins, 10 5-cent coins, 10 2-cent coins, 2 1-cent coins')

        # Step 2: Purchase Candy (75 cents) with €1 coin, expecting 25 cents change
        vending_machine.start_purchase('Candy')
        purchase_result = vending_machine.insert_payment({ 100 => 1 })

        # Verify purchase message with change
        expect(purchase_result).to eq('Thank you for your purchase of Candy. Please collect your item and change: 1 x 20c, 1 x 5c')

        # Step 3: Check updated balance after purchase
        # Balance increased by 100c (payment) - 25c (change given) = 75c net increase
        updated_balance_total = vending_machine.available_change
        updated_balance_english = vending_machine.balance_in_english

        expect(updated_balance_total).to eq(1147) # €11.47 in cents (1072 + 75)
        # After giving change: €1 coin added, but 1x20c and 1x5c removed
        expect(updated_balance_english).to eq('1 2 Euro coin, 3 1 Euro coins, 6 50-cent coins, 9 20-cent coins, 10 10-cent coins, 9 5-cent coins, 10 2-cent coins, 2 1-cent coins')

        # Step 4: Reload change with 1 €1 coin and 2 50c coins
        reload_result = vending_machine.reload_change({ 100 => 1, 50 => 2 })

        # Verify reload message
        expect(reload_result).to eq('Successfully added coins: 1 1 Euro coin, 2 50-cent coins. Total balance: €13.47')

        # Step 5: Final balance check
        final_balance_total = vending_machine.available_change
        final_balance_english = vending_machine.balance_in_english

        # Verify final balance
        expect(final_balance_total).to eq(1347) # €13.47 in cents (1147 + 200)
        # After reload: added 1x€1 and 2x50c to previous balance
        expect(final_balance_english).to eq('1 2 Euro coin, 4 1 Euro coins, 8 50-cent coins, 9 20-cent coins, 10 10-cent coins, 9 5-cent coins, 10 2-cent coins, 2 1-cent coins')
      end
    end

    describe 'excessive money handling' do
      context 'when user overpays for items' do
        it 'returns appropriate change for single overpayment' do
          vending_machine = cli.instance_variable_get(:@vending_machine)
          initial_balance = vending_machine.balance.calculate_total_amount

          # Start purchase for Candy (75 cents)
          vending_machine.start_purchase('Candy')

          # Pay with €2 (200 cents), expecting €1.25 change
          result = vending_machine.insert_payment({ 200 => 1 })

          # Verify the message includes item name and specific change denominations
          expect(result).to eq('Thank you for your purchase of Candy. Please collect your item and change: 1 x 100c, 1 x 20c, 1 x 5c')

          # Net change in balance: +200 cents (received) - 125 cents (change given) = +75 cents
          expected_balance = initial_balance + 75
          final_balance = vending_machine.balance.calculate_total_amount
          expect(final_balance).to eq(expected_balance)

          candy_item = vending_machine.items.find { |item| item.name == 'Candy' }
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
