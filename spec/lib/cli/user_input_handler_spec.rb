require 'spec_helper'
require_relative '../../../lib/cli/user_input_handler'

RSpec.describe UserInputHandler do
  let(:handler) { described_class.new }

  describe '#get_menu_choice' do
    it 'returns user input converted to lowercase' do
      allow($stdin).to receive(:gets).and_return("1\n")
      expect(handler.get_menu_choice).to eq('1')
    end

    it 'handles uppercase input by converting to lowercase' do
      allow($stdin).to receive(:gets).and_return("Q\n")
      expect(handler.get_menu_choice).to eq('q')
    end

    it 'returns q when input is nil (EOF)' do
      allow($stdin).to receive(:gets).and_return(nil)
      expect(handler.get_menu_choice).to eq('q')
    end

    it 'removes trailing newlines from input' do
      allow($stdin).to receive(:gets).and_return("quit\n")
      expect(handler.get_menu_choice).to eq('quit')
    end
  end

  describe '#get_item_number' do
    it 'prompts user and returns integer from input' do
      allow($stdin).to receive(:gets).and_return("3\n")
      expect { handler.get_item_number }.to output('Enter item number to purchase: ').to_stdout
    end

    it 'returns nil when input is nil (EOF)' do
      allow($stdin).to receive(:gets).and_return(nil)
      expect { handler.get_item_number }.to output('Enter item number to purchase: ').to_stdout
    end

    it 'converts non-numeric input to integer (0)' do
      allow($stdin).to receive(:gets).and_return("abc\n")
      expect { handler.get_item_number }.to output('Enter item number to purchase: ').to_stdout
    end
  end

  describe '#get_payment_input' do
    it 'prompts user and returns payment input string' do
      allow($stdin).to receive(:gets).and_return("{100 => 2}\n")
      expect { handler.get_payment_input }.to output("Enter payment hash (or 'cancel' to cancel): ").to_stdout
    end

    it 'returns nil when input is nil (EOF)' do
      allow($stdin).to receive(:gets).and_return(nil)
      expect { handler.get_payment_input }.to output("Enter payment hash (or 'cancel' to cancel): ").to_stdout
    end

    it 'handles cancel input' do
      allow($stdin).to receive(:gets).and_return("cancel\n")
      expect { handler.get_payment_input }.to output("Enter payment hash (or 'cancel' to cancel): ").to_stdout
    end
  end

  describe '#request_any_key' do
    it 'prompts user to press enter and waits for input' do
      allow($stdin).to receive(:gets).and_return("\n")
      expect { handler.request_any_key }.to output('Press Enter to continue...').to_stdout
    end

    it 'handles nil input gracefully' do
      allow($stdin).to receive(:gets).and_return(nil)
      expect { handler.request_any_key }.to output('Press Enter to continue...').to_stdout
    end
  end
end
