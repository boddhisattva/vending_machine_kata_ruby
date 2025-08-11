describe ChangeReloader do
  let(:reloader) { ChangeReloader.new }
  let(:balance) { Change.new({ 100 => 2, 50 => 2 }) }

  describe '#reload_change' do
    context 'successful reload' do
      it 'adds coins and returns success message' do
        result, new_balance = reloader.reload_change(balance, { 100 => 3, 50 => 2 })
        expect(result).to include('Successfully added coins')
        expect(result).to include('3 1 Euro coins, 2 50-cent coins')
        expect(result).to include('Total balance: €7.00')

        # Verify new balance
        expect(new_balance.amount[100]).to eq(5) # 2 + 3
        expect(new_balance.amount[50]).to eq(4)  # 2 + 2
      end

      it 'handles new denominations not in current balance' do
        result, new_balance = reloader.reload_change(balance, { 20 => 5, 5 => 10 })
        expect(result).to include('Successfully added coins')
        expect(new_balance.amount[20]).to eq(5)
        expect(new_balance.amount[5]).to eq(10)
      end

      it 'returns new Change object, not modifying original' do
        original_amount = balance.amount.dup
        _, new_balance = reloader.reload_change(balance, { 100 => 1 })

        expect(balance.amount).to eq(original_amount)
        expect(new_balance).not_to eq(balance)
      end
    end

    context 'validation errors' do
      let(:mock_validator) { double('ReloadValidator') }
      let(:reloader_with_mock) { ChangeReloader.new(mock_validator) }

      it 'returns error when validator returns an error message' do
        error_message = 'Invalid coin denominations: [25]'
        expect(mock_validator).to receive(:validate_coin_reload)
          .with({ 25 => 5 })
          .and_return(error_message)

        result, returned_balance = reloader_with_mock.reload_change(balance, { 25 => 5 })
        expect(result).to eq(error_message)
        expect(returned_balance).to eq(balance)
      end
    end

    context 'with custom validator' do
      let(:mock_validator) { double('ReloadValidator') }
      let(:reloader_with_validator) { ChangeReloader.new(mock_validator) }

      it 'uses injected validator' do
        expect(mock_validator).to receive(:validate_coin_reload)
          .with({ 100 => 5 })
          .and_return(nil)

        allow(mock_validator).to receive(:validate_coin_reload).and_return(nil)
        reloader_with_validator.reload_change(balance, { 100 => 5 })
      end
    end
  end
end
