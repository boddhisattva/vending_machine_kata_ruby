# frozen_string_literal: true


RSpec.describe PurchaseExecutor do
  let(:display) { double('VendingMachineDisplay') }
  let(:input_handler) { double('UserInputHandler') }
  let(:item_selector) { double('ItemSelector') }
  let(:purchase_orchestrator) { double('PurchaseSessionOrchestrator') }

  let(:executor) do
    described_class.new(display, input_handler, item_selector, purchase_orchestrator)
  end

  describe '#initialize' do
    it 'accepts all required dependencies' do
      expect(executor).to be_a(PurchaseExecutor)
    end
  end

  describe '#execute' do
    let(:item) { double('Item', name: 'Coke') }
    let(:item_number) { 1 }

    before do
      allow(display).to receive(:show_available_items)
    end

    it 'displays purchase header and available items' do
      allow(input_handler).to receive(:get_item_number).and_return(nil)

      expect { executor.execute }.to output("\n=== Purchase Item with Session ===\n").to_stdout
      expect(display).to have_received(:show_available_items)
    end

    context 'when user provides valid item number' do
      before do
        allow(input_handler).to receive(:get_item_number).and_return(item_number)
        allow(item_selector).to receive(:select_item_for_purchase).with(item_number).and_return(item)
        allow(purchase_orchestrator).to receive(:execute_purchase_for).with(item)
      end

      it 'gets item number from input handler' do
        executor.execute
        expect(input_handler).to have_received(:get_item_number)
      end

      it 'selects item using item selector' do
        executor.execute
        expect(item_selector).to have_received(:select_item_for_purchase).with(item_number)
      end

      it 'executes purchase using orchestrator' do
        executor.execute
        expect(purchase_orchestrator).to have_received(:execute_purchase_for).with(item)
      end
    end

    context 'when input handler returns nil (user cancels or EOF)' do
      before do
        allow(input_handler).to receive(:get_item_number).and_return(nil)
      end

      it 'does not proceed with item selection' do
        expect(item_selector).not_to receive(:select_item_for_purchase)
        executor.execute
      end

      it 'does not execute purchase' do
        expect(purchase_orchestrator).not_to receive(:execute_purchase_for)
        executor.execute
      end
    end

    context 'when item selector returns nil (invalid item)' do
      before do
        allow(input_handler).to receive(:get_item_number).and_return(item_number)
        allow(item_selector).to receive(:select_item_for_purchase).with(item_number).and_return(nil)
      end

      it 'does not execute purchase' do
        expect(purchase_orchestrator).not_to receive(:execute_purchase_for)
        executor.execute
      end
    end

    context 'when item selector returns valid item' do
      before do
        allow(input_handler).to receive(:get_item_number).and_return(item_number)
        allow(item_selector).to receive(:select_item_for_purchase).with(item_number).and_return(item)
        allow(purchase_orchestrator).to receive(:execute_purchase_for).with(item)
      end

      it 'executes purchase for the selected item' do
        executor.execute
        expect(purchase_orchestrator).to have_received(:execute_purchase_for).with(item)
      end
    end
  end
end
