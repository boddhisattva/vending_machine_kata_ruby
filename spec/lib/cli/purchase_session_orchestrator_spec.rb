require 'spec_helper'
require_relative '../../../lib/cli/purchase_session_orchestrator'

RSpec.describe PurchaseSessionOrchestrator do
  let(:vending_machine) { double('VendingMachine') }
  let(:payment_parser) { double('PaymentInputParser') }
  let(:display) { double('VendingMachineDisplay') }
  let(:input_handler) { double('UserInputHandler') }
  let(:orchestrator) { described_class.new(vending_machine, payment_parser, display, input_handler) }
  let(:item) { double('Item', name: 'Coke') }

  describe '#execute_purchase_for' do
    it 'starts purchase session and collects payment until complete' do
      allow(vending_machine).to receive(:start_purchase).with('Coke').and_return('Purchase started for Coke')
      allow(display).to receive(:show_payment_instructions)
      allow(input_handler).to receive(:get_payment_input).and_return('{100 => 2}')
      allow(payment_parser).to receive(:parse).with('{100 => 2}').and_return({ 100 => 2 })
      allow(vending_machine).to receive(:insert_payment).with({ 100 => 2 }).and_return('Payment complete! Thank you for your purchase')

      expected_output = [
        'Starting purchase session...',
        'Purchase started for Coke',
        '',
        'Payment complete! Thank you for your purchase'
      ].join("\n") + "\n"

      expect { orchestrator.execute_purchase_for(item) }.to output(expected_output).to_stdout
    end

    it 'handles insufficient payment and continues collecting until complete' do
      allow(vending_machine).to receive(:start_purchase).with('Coke').and_return('Purchase started for Coke')
      allow(display).to receive(:show_payment_instructions)
      allow(input_handler).to receive(:get_payment_input).and_return('{50 => 1}', '{100 => 1}')
      allow(payment_parser).to receive(:parse).with('{50 => 1}').and_return({ 50 => 1 })
      allow(payment_parser).to receive(:parse).with('{100 => 1}').and_return({ 100 => 1 })
      allow(vending_machine).to receive(:insert_payment).with({ 50 => 1 }).and_return('Insufficient payment. Please insert more money.')
      allow(vending_machine).to receive(:insert_payment).with({ 100 => 1 }).and_return('Payment complete! Thank you for your purchase')

      expected_output = [
        'Starting purchase session...',
        'Purchase started for Coke',
        '',
        'Insufficient payment. Please insert more money.',
        '',
        'Payment complete! Thank you for your purchase'
      ].join("\n") + "\n"

      expect { orchestrator.execute_purchase_for(item) }.to output(expected_output).to_stdout
    end

    it 'handles user cancellation' do
      allow(vending_machine).to receive(:start_purchase).with('Coke').and_return('Purchase started for Coke')
      allow(display).to receive(:show_payment_instructions)
      allow(input_handler).to receive(:get_payment_input).and_return('cancel')
      allow(vending_machine).to receive(:cancel_purchase).and_return('Purchase cancelled. Coins returned.')

      expected_output = [
        'Starting purchase session...',
        'Purchase started for Coke',
        '',
        'Purchase cancelled. Coins returned.'
      ].join("\n") + "\n"

      expect { orchestrator.execute_purchase_for(item) }.to output(expected_output).to_stdout
    end

    it 'handles invalid payment format and allows retry' do
      allow(vending_machine).to receive(:start_purchase).with('Coke').and_return('Purchase started for Coke')
      allow(display).to receive(:show_payment_instructions)
      allow(input_handler).to receive(:get_payment_input).and_return('invalid format', '{100 => 2}')
      allow(payment_parser).to receive(:parse).with('invalid format').and_return(nil)
      allow(payment_parser).to receive(:parse).with('{100 => 2}').and_return({ 100 => 2 })
      allow(vending_machine).to receive(:insert_payment).with({ 100 => 2 }).and_return('Payment complete! Thank you for your purchase')

      expected_output = [
        'Starting purchase session...',
        'Purchase started for Coke',
        '',
        '',
        'Payment complete! Thank you for your purchase'
      ].join("\n") + "\n"

      expect { orchestrator.execute_purchase_for(item) }.to output(expected_output).to_stdout
    end

    it 'handles nil input (EOF) gracefully' do
      allow(vending_machine).to receive(:start_purchase).with('Coke').and_return('Purchase started for Coke')
      allow(display).to receive(:show_payment_instructions)
      allow(input_handler).to receive(:get_payment_input).and_return(nil)

      expected_output = [
        'Starting purchase session...',
        'Purchase started for Coke',
        ''
      ].join("\n") + "\n"

      expect { orchestrator.execute_purchase_for(item) }.to output(expected_output).to_stdout
    end

    it 'handles parser exceptions gracefully' do
      allow(vending_machine).to receive(:start_purchase).with('Coke').and_return('Purchase started for Coke')
      allow(display).to receive(:show_payment_instructions)
      allow(input_handler).to receive(:get_payment_input).and_return('{100 => 2}', 'cancel')
      allow(payment_parser).to receive(:parse).with('{100 => 2}').and_raise(StandardError.new('Parser error'))
      allow(vending_machine).to receive(:cancel_purchase).and_return('Purchase cancelled.')

      expected_output = [
        'Starting purchase session...',
        'Purchase started for Coke',
        '',
        'Error processing payment: Parser error',
        'Please use the format: {100 => 2, 25 => 1}',
        '',
        'Purchase cancelled.'
      ].join("\n") + "\n"

      expect { orchestrator.execute_purchase_for(item) }.to output(expected_output).to_stdout
    end

    it 'recognizes different completion messages' do
      allow(vending_machine).to receive(:start_purchase).with('Coke').and_return('Purchase started for Coke')
      allow(display).to receive(:show_payment_instructions)
      allow(input_handler).to receive(:get_payment_input).and_return('{100 => 2}')
      allow(payment_parser).to receive(:parse).with('{100 => 2}').and_return({ 100 => 2 })
      allow(vending_machine).to receive(:insert_payment).with({ 100 => 2 }).and_return('Thank you for your purchase! Enjoy your item.')

      expected_output = [
        'Starting purchase session...',
        'Purchase started for Coke',
        '',
        'Thank you for your purchase! Enjoy your item.'
      ].join("\n") + "\n"

      expect { orchestrator.execute_purchase_for(item) }.to output(expected_output).to_stdout
    end

    it 'recognizes payment refunded completion message' do
      allow(vending_machine).to receive(:start_purchase).with('Coke').and_return('Purchase started for Coke')
      allow(display).to receive(:show_payment_instructions)
      allow(input_handler).to receive(:get_payment_input).and_return('{100 => 2}')
      allow(payment_parser).to receive(:parse).with('{100 => 2}').and_return({ 100 => 2 })
      allow(vending_machine).to receive(:insert_payment).with({ 100 => 2 }).and_return('Payment refunded: €2.00. Cannot make exact change.')

      expected_output = [
        'Starting purchase session...',
        'Purchase started for Coke',
        '',
        'Payment refunded: €2.00. Cannot make exact change.'
      ].join("\n") + "\n"

      expect { orchestrator.execute_purchase_for(item) }.to output(expected_output).to_stdout
    end
  end
end
