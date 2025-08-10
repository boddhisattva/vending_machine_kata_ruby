# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/cli/menu_router'

RSpec.describe MenuRouter do
  let(:display) { double('VendingMachineDisplay') }
  let(:item_reloader) { double('ItemReloadHandler') }
  let(:change_reloader) { double('ChangeReloadHandler') }
  let(:purchase_executor) { double('PurchaseExecutor') }

  let(:router) do
    described_class.new(display, item_reloader, change_reloader, purchase_executor)
  end

  describe '#initialize' do
    it 'accepts all required dependencies' do
      expect(router).to be_a(MenuRouter)
    end
  end

  describe '#route' do
    context 'when choice is "1"' do
      it 'shows available items' do
        expect(display).to receive(:show_available_items)
        router.route('1')
      end
    end

    context 'when choice is "2"' do
      it 'executes purchase flow' do
        expect(purchase_executor).to receive(:execute)
        router.route('2')
      end
    end

    context 'when choice is "3"' do
      it 'shows current balance' do
        expect(display).to receive(:show_current_balance)
        router.route('3')
      end
    end

    context 'when choice is "4"' do
      it 'shows machine status' do
        expect(display).to receive(:show_machine_status)
        router.route('4')
      end
    end

    context 'when choice is "5"' do
      it 'reloads items for machine' do
        expect(item_reloader).to receive(:reload_items_for_machine)
        router.route('5')
      end
    end

    context 'when choice is "6"' do
      it 'reloads change for machine' do
        expect(change_reloader).to receive(:reload_change_for_machine)
        router.route('6')
      end
    end

    context 'when choice is quit command' do
      %w[q quit exit].each do |quit_command|
        context "when choice is #{quit_command}" do
          it 'shows goodbye message' do
            expect(display).to receive(:show_goodbye_message)
            router.route(quit_command)
          end
        end
      end
    end

    context 'when choice is invalid' do
      ['0', '7', '8', '9', 'invalid', 'abc', ''].each do |invalid_choice|
        context "when choice is #{invalid_choice.inspect}" do
          it 'shows invalid choice message' do
            expect(display).to receive(:show_invalid_choice_message)
            router.route(invalid_choice)
          end
        end
      end
    end
  end

  describe '#quit_command?' do
    context 'when input is a quit command' do
      %w[q quit exit].each do |quit_command|
        it "returns true for #{quit_command}" do
          expect(router.quit_command?(quit_command)).to be true
        end
      end
    end

    context 'when input is not a quit command' do
      ['1', '2', '3', '4', '5', '6', 'Q', 'QUIT', 'EXIT', 'invalid', ''].each do |non_quit_command|
        it "returns false for #{non_quit_command.inspect}" do
          expect(router.quit_command?(non_quit_command)).to be false
        end
      end
    end
  end
end
