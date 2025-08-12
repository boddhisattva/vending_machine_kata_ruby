#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/vending_machine'
require_relative '../lib/item'
require_relative '../lib/change'
require_relative '../lib/cli/vending_machine_display'
require_relative '../lib/cli/payment_input_parser'
require_relative '../lib/cli/user_input_handler'
require_relative '../lib/cli/item_selector'
require_relative '../lib/cli/purchase_session_orchestrator'
require_relative '../lib/cli/currency_formatter'
require_relative '../lib/cli/vending_machine_initializer'
require_relative '../lib/cli/item_load_handler'
require_relative '../lib/cli/change_reload_handler'
require_relative '../lib/cli/menu_router'
require_relative '../lib/cli/purchase_executor'
require_relative '../lib/cli/application_runner'

class VendingMachineCLI
  def initialize
    setup_core_components
    setup_cli_components
    setup_router_and_runner
  end

  def run
    @runner.run
  end

  private

  def setup_core_components
    @initializer = VendingMachineInitializer.new
    @vending_machine = @initializer.initialize_vending_machine
    @currency_formatter = CurrencyFormatter.new
  end

  def setup_cli_components
    @display = VendingMachineDisplay.new(@vending_machine, @currency_formatter)
    @input_handler = UserInputHandler.new
    @payment_parser = PaymentInputParser.new
    @item_selector = ItemSelector.new(@vending_machine, @currency_formatter)

    @purchase_orchestrator = PurchaseSessionOrchestrator.new(
      @vending_machine,
      @payment_parser,
      @display,
      @input_handler
    )

    @item_load_handler = ItemLoadHandler.new(@vending_machine, @display, @input_handler)
    @change_reloader = ChangeReloadHandler.new(
      @vending_machine,
      @currency_formatter,
      @payment_parser,
      @input_handler
    )
  end

  def setup_router_and_runner
    @purchase_executor = PurchaseExecutor.new(
      @display,
      @input_handler,
      @item_selector,
      @purchase_orchestrator
    )

    @menu_router = MenuRouter.new(
      @display,
      @item_load_handler,
      @change_reloader,
      @purchase_executor
    )

    @runner = ApplicationRunner.new(
      @display,
      @input_handler,
      @menu_router
    )
  end
end

if __FILE__ == $PROGRAM_NAME
  cli = VendingMachineCLI.new
  cli.run
end
