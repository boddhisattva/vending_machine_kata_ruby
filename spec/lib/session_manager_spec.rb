RSpec.describe SessionManager do
  subject(:session_manager) { described_class.new }

  describe '#start_session' do
    it 'raises NotImplementedError as it is an abstract method' do
      item = double('Item')
      expect { session_manager.start_session(item) }
        .to raise_error(NotImplementedError, 'Subclasses must implement start_session')
    end
  end

  describe '#add_payment' do
    it 'raises NotImplementedError as it is an abstract method' do
      expect { session_manager.add_payment('session_123', { 100 => 1 }) }
        .to raise_error(NotImplementedError, 'Subclasses must implement add_payment')
    end
  end

  describe '#complete_session' do
    it 'raises NotImplementedError as it is an abstract method' do
      expect { session_manager.complete_session('session_123') }
        .to raise_error(NotImplementedError, 'Subclasses must implement complete_session')
    end
  end

  describe '#cancel_session' do
    it 'raises NotImplementedError as it is an abstract method' do
      expect { session_manager.cancel_session('session_123') }
        .to raise_error(NotImplementedError, 'Subclasses must implement cancel_session')
    end
  end
end
