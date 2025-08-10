# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/cli/application_runner'

RSpec.describe ApplicationRunner do
  let(:display) { double('VendingMachineDisplay') }
  let(:input_handler) { double('UserInputHandler') }
  let(:menu_router) { double('MenuRouter') }

  let(:runner) do
    described_class.new(display, input_handler, menu_router)
  end

  describe '#initialize' do
    it 'accepts all required dependencies' do
      expect(runner).to be_a(ApplicationRunner)
    end
  end

  describe '#run' do
    before do
      allow(display).to receive(:show_welcome_message)
      allow(display).to receive(:show_menu_options)
      allow(menu_router).to receive(:route)
    end

    context 'when user immediately quits' do
      before do
        allow(input_handler).to receive(:get_menu_choice).and_return('q')
        allow(menu_router).to receive(:quit_command?).with('q').and_return(true)
      end

      it 'shows welcome message' do
        runner.run
        expect(display).to have_received(:show_welcome_message)
      end

      it 'shows menu options once & exits the loop after quit command' do
        runner.run
        expect(display).to have_received(:show_menu_options).once
      end

      it 'gets menu choice from input handler' do
        runner.run
        expect(input_handler).to have_received(:get_menu_choice)
      end

      it 'routes the choice through menu router' do
        runner.run
        expect(menu_router).to have_received(:route).with('q')
      end

      it 'checks if choice is quit command' do
        runner.run
        expect(menu_router).to have_received(:quit_command?).with('q')
      end
    end

    context 'when user makes multiple choices before quitting' do
      before do
        allow(input_handler).to receive(:get_menu_choice).and_return('1', '2', '3', 'quit')
        allow(menu_router).to receive(:quit_command?).and_return(false, false, false, true)
      end

      it 'shows menu options multiple times' do
        runner.run
        expect(display).to have_received(:show_menu_options).exactly(4).times
      end

      it 'routes each choice through menu router & checks quit command for each choice' do
        runner.run
        expect(menu_router).to have_received(:route).with('1')
        expect(menu_router).to have_received(:quit_command?).with('1')

        expect(menu_router).to have_received(:route).with('2')
        expect(menu_router).to have_received(:quit_command?).with('2')

        expect(menu_router).to have_received(:route).with('3')
        expect(menu_router).to have_received(:quit_command?).with('3')

        expect(menu_router).to have_received(:route).with('quit')
      end

      it 'prints newline after each iteration except the last' do
        expect { runner.run }.to output(/\n\n\n/).to_stdout
      end
    end

    context 'when handling the application loop flow' do
      before do
        allow(input_handler).to receive(:get_menu_choice).and_return('1', 'exit')
        allow(menu_router).to receive(:quit_command?).and_return(false, true)
      end

      it 'follows the correct sequence' do
        expect(display).to receive(:show_welcome_message).ordered
        expect(display).to receive(:show_menu_options).ordered
        expect(input_handler).to receive(:get_menu_choice).ordered
        expect(menu_router).to receive(:route).ordered
        expect(menu_router).to receive(:quit_command?).ordered

        runner.run
      end
    end
  end
end
