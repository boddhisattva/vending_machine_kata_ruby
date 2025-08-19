# frozen_string_literal: true

describe 'Purchase Flow Integration Tests - Full CLI Stack' do
  INITIAL_ITEMS = [
    { name: 'Coke', price: 150, quantity: 5 },
    { name: 'Chips', price: 100, quantity: 3 },
    { name: 'Candy', price: 75, quantity: 8 },
    { name: 'Water', price: 125, quantity: 2 },
    { name: 'Watermelon Juice', price: 100, quantity: 0 } # Out of stock for testing
  ].freeze

  INITIAL_BALANCE = {
    50 => 6,
    10 => 10,
    20 => 10,
    100 => 2,
    200 => 1,
    5 => 10,
    2 => 10,
    1 => 2
  }.freeze

  def create_vending_machine
    items = INITIAL_ITEMS.map { |data| Item.new(data[:name], data[:price], data[:quantity]) }
    balance = Change.new(INITIAL_BALANCE)
    VendingMachine.new(items, balance)
  end

  let(:vending_machine) { create_vending_machine }
  let(:currency_formatter) { CurrencyFormatter.new }
  let(:display) { VendingMachineDisplay.new(vending_machine, currency_formatter) }
  let(:input_handler) { UserInputHandler.new }
  let(:payment_parser) { PaymentInputParser.new }
  let(:item_selector) { ItemSelector.new(vending_machine, currency_formatter) }

  let(:purchase_orchestrator) do
    PurchaseSessionOrchestrator.new(vending_machine, payment_parser, display, input_handler)
  end
  let(:purchase_executor) { PurchaseExecutor.new(display, input_handler, item_selector, purchase_orchestrator) }
  let(:item_load_handler) { ItemLoadHandler.new(vending_machine, display, input_handler) }
  let(:change_reload_handler) { ChangeReloadHandler.new(vending_machine, display, input_handler, payment_parser) }
  let(:menu_router) { MenuRouter.new(display, item_load_handler, change_reload_handler, purchase_executor) }
  let(:application_runner) { ApplicationRunner.new(display, input_handler, menu_router) }

  before do
    # Suppress all output during tests
    # Without stubbing puts, all the display messages would be printed to the
    # console during test execution, making the test output noisy and harder to read.
    allow($stdout).to receive(:write)
    allow($stdout).to receive(:puts)
    allow(display).to receive(:puts)
    allow(display).to receive(:print)
    allow(purchase_executor).to receive(:puts)
    allow(purchase_orchestrator).to receive(:puts)
    allow(purchase_orchestrator).to receive(:print)
  end

  describe 'Purchase with change through full stack' do
    it 'handles overpayment through complete CLI flow (ApplicationRunner -> MenuRouter -> PurchaseExecutor)' do
      # Find Candy item (costs €0.75 = 75 cents)
      candy_item = vending_machine.items.find { |item| item.name == 'Candy' }
      initial_quantity = candy_item.quantity
      initial_balance = vending_machine.available_change

      # Mock user interactions for the complete flow:
      # 1. User selects option '2' (Purchase) from main menu
      # 2. User selects item 3 (Candy)
      # 3. User enters payment {100 => 1}
      # 4. User selects 'q' to quit after purchase
      allow(input_handler).to receive(:get_menu_choice).and_return('2', 'q')
      allow(input_handler).to receive(:get_item_number).and_return(3)
      allow(input_handler).to receive(:get_payment_input).and_return('{100 => 1}', nil)

      application_runner.run

      expect(candy_item.quantity).to eq(initial_quantity - 1)
      expect(vending_machine.available_change).to eq(initial_balance + 75)
    end
  end

  describe 'Multiple payments through complete CLI flow' do
    it 'handles insufficient initial payment through full ApplicationRunner flow' do
      # Find Coke item (costs €1.50 = 150 cents)
      coke_item = vending_machine.items.find { |item| item.name == 'Coke' }
      initial_quantity = coke_item.quantity
      initial_balance = vending_machine.available_change

      allow(input_handler).to receive(:get_menu_choice).and_return('2', 'q')
      allow(input_handler).to receive(:get_item_number).and_return(1)
      allow(input_handler).to receive(:get_payment_input).and_return(
        '{50 => 1}',  # First payment - insufficient
        '{20 => 2}',  # Second payment - still insufficient
        '{50 => 1}',  # Third payment - still insufficient
        '{10 => 1}',  # Fourth payment - completes purchase
        nil
      )

      application_runner.run

      expect(coke_item.quantity).to eq(initial_quantity - 1)
      expect(vending_machine.available_change).to eq(initial_balance + 150)
    end
  end

  describe 'Cancel purchase with refund through full stack' do
    it 'processes cancellation through full ApplicationRunner flow with proper refund' do
      water_item = vending_machine.items.find { |item| item.name == 'Water' }
      initial_quantity = water_item.quantity
      initial_balance = vending_machine.available_change

      allow(input_handler).to receive(:get_menu_choice).and_return('2', 'q')
      allow(input_handler).to receive(:get_item_number).and_return(4)
      allow(input_handler).to receive(:get_payment_input).and_return(
        '{50 => 1}',  # Initial payment
        '{20 => 1}',  # Second payment
        'cancel',     # Cancel command
        nil
      )

      application_runner.run

      expect(water_item.quantity).to eq(initial_quantity)
      expect(vending_machine.available_change).to eq(initial_balance)
    end
  end

  describe 'Insufficient change auto-cancel through full stack' do
    it 'handles auto-cancel scenario through complete ApplicationRunner flow when change unavailable' do
      limited_balance = { 200 => 1 }
      limited_change = Change.new(limited_balance)
      items = [
        Item.new('Test Item', 150, 5),
        Item.new('Exact Item', 200, 3)
      ]
      limited_machine = VendingMachine.new(items, limited_change)

      limited_display = VendingMachineDisplay.new(limited_machine, currency_formatter)
      limited_item_selector = ItemSelector.new(limited_machine, currency_formatter)
      limited_orchestrator = PurchaseSessionOrchestrator.new(limited_machine, payment_parser, limited_display,
                                                             input_handler)
      limited_executor = PurchaseExecutor.new(limited_display, input_handler, limited_item_selector,
                                              limited_orchestrator)
      limited_item_load = ItemLoadHandler.new(limited_machine, limited_display, input_handler)
      limited_change_reload = ChangeReloadHandler.new(limited_machine, currency_formatter, payment_parser,
                                                      input_handler)
      limited_router = MenuRouter.new(limited_display, limited_item_load, limited_change_reload, limited_executor)
      limited_runner = ApplicationRunner.new(limited_display, input_handler, limited_router)

      # Suppress output for limited machine
      # Without stubbing puts, all the display messages would be printed to the
      # console during test execution, making the test output noisy and harder to read.
      allow(limited_display).to receive(:puts)
      allow(limited_executor).to receive(:puts)
      allow(limited_orchestrator).to receive(:puts)

      test_item = limited_machine.items.first
      initial_quantity = test_item.quantity

      allow(input_handler).to receive(:get_menu_choice).and_return('2', 'q')
      allow(input_handler).to receive(:get_item_number).and_return(1)
      allow(input_handler).to receive(:get_payment_input).and_return('{200 => 1}', nil)

      limited_runner.run

      expect(test_item.quantity).to eq(initial_quantity)
      expect(limited_machine.available_change).to eq(200)
    end
  end

  describe 'Out of stock handling through full ApplicationRunner flow' do
    it 'handles out-of-stock scenario through complete CLI flow' do
      # Watermelon Juice is out of stock (quantity = 0)
      out_of_stock_item = vending_machine.items.find { |item| item.name == 'Watermelon Juice' }
      expect(out_of_stock_item.quantity).to eq(0)
      initial_balance = vending_machine.available_change

      allow(input_handler).to receive(:get_menu_choice).and_return('2', 'q')
      allow(input_handler).to receive(:get_item_number).and_return(5)
      # If purchase can't start due to out of stock, payment won't be requested
      # session_started is false in PurchaseSessionOrchestrator#start_purchase_session_for

      application_runner.run

      # Verify no purchase was made
      expect(out_of_stock_item.quantity).to eq(0)
      expect(vending_machine.available_change).to eq(initial_balance)
    end
  end

  describe 'Invalid payment denomination through full stack' do
    it 'validates coins through full ApplicationRunner flow' do
      chips_item = vending_machine.items.find { |item| item.name == 'Chips' }
      initial_quantity = chips_item.quantity
      initial_balance = vending_machine.available_change

      allow(input_handler).to receive(:get_menu_choice).and_return('2', 'q')
      allow(input_handler).to receive(:get_item_number).and_return(2)
      allow(input_handler).to receive(:get_payment_input).and_return(
        '{300 => 1}',  # Invalid €3 coin
        '{100 => 1}',  # Valid payment after error
        nil
      )

      application_runner.run

      expect(chips_item.quantity).to eq(initial_quantity - 1)
      expect(vending_machine.available_change).to eq(initial_balance + 100)
    end
  end

  describe 'Complex scenario: Multiple operations through ApplicationRunner' do
    it 'simulates a complete user session with multiple menu selections through ApplicationRunner' do
      initial_coke_quantity = vending_machine.items.find { |i| i.name == 'Coke' }.quantity
      initial_balance = vending_machine.available_change

      # Simulate complete user session:
      # 1. Display items (option 1)
      # 2. Check balance (option 3)
      # 3. Purchase item (option 2)
      # 4. Check status (option 4)
      # 5. Quit (option q)
      menu_choices = %w[1 3 2 4 q]
      choice_index = 0

      allow(input_handler).to receive(:get_menu_choice) do
        choice = menu_choices[choice_index]
        choice_index += 1
        choice
      end

      # For the purchase flow
      allow(input_handler).to receive(:get_item_number).and_return(1) # Select Coke
      allow(input_handler).to receive(:get_payment_input).and_return(
        '{100 => 1}',
        '{50 => 1}',
        nil
      )

      application_runner.run

      final_coke_quantity = vending_machine.items.find { |i| i.name == 'Coke' }.quantity
      expect(final_coke_quantity).to eq(initial_coke_quantity - 1)
      expect(vending_machine.available_change).to eq(initial_balance + 150)
    end
  end
end
