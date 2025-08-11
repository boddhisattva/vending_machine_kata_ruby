
RSpec.describe PaymentInputParser do
  let(:parser) { described_class.new }

  describe '#parse' do
    context 'with valid hash input' do
      it 'parses simple single coin payment' do
        result = parser.parse('{100 => 2}')
        expect(result).to eq({ 100 => 2 })
      end

      it 'parses multiple coin denominations' do
        result = parser.parse('{100 => 2, 50 => 1, 10 => 3}')
        expect(result).to eq({ 100 => 2, 50 => 1, 10 => 3 })
      end

      it 'handles whitespace variations' do
        result = parser.parse('{ 100=>2 , 50 => 1 }')
        expect(result).to eq({ 100 => 2, 50 => 1 })
      end

      it 'returns empty hash for empty content' do
        expect(parser.parse('{}')).to eq({})
        expect(parser.parse('{ }')).to eq({})
      end
    end

    context 'with invalid format' do
      it 'returns nil and shows error for non-hash format' do
        expect { parser.parse('100 => 2') }.to output(/Invalid format/).to_stdout
        expect(parser.parse('100 => 2')).to be_nil
      end

      it 'returns nil and shows error for missing braces' do
        expect { parser.parse('100 => 2, 50 => 1') }.to output(/Invalid format/).to_stdout
        expect(parser.parse('100 => 2, 50 => 1')).to be_nil
      end

      it 'returns nil and shows error for malformed pairs' do
        expect { parser.parse('{100 = 2}') }.to output(/Invalid pair format/).to_stdout
        expect(parser.parse('{100 = 2}')).to be_nil
      end

      it 'returns nil and shows error for invalid count' do
        expect { parser.parse('{100 => 0}') }.to output(/Invalid count/).to_stdout
        result = parser.parse('{100 => 0}')
        expect(result).to be_nil
      end

      it 'handles negative numbers as invalid format' do
        expect { parser.parse('{100 => -1}') }.to output(/Invalid pair format/).to_stdout
        result = parser.parse('{100 => -1}')
        expect(result).to be_nil
      end

      it 'handles mixed valid and invalid entries' do
        expect { parser.parse('{100 => 2, 50 = 1}') }.to output(/Invalid pair format/).to_stdout
        expect(parser.parse('{100 => 2, 50 = 1}')).to be_nil
      end
    end

    context 'with edge cases' do
      it 'handles single denomination with large count' do
        result = parser.parse('{1 => 100}')
        expect(result).to eq({ 1 => 100 })
      end

      it 'handles large denomination values' do
        result = parser.parse('{200 => 5}')
        expect(result).to eq({ 200 => 5 })
      end

      it 'returns nil for completely malformed input and shows helpful error' do
        expect { parser.parse('garbage input') }.to output(/Invalid format/).to_stdout
        expect(parser.parse('garbage input')).to be_nil
      end
    end

    context 'when exceptions occur' do
      it 'catches and handles parsing errors gracefully' do
        allow(parser).to receive(:extract_hash_content).and_raise(StandardError.new('Test error'))

        expect { parser.parse('{100 => 2}') }.to output(/Error parsing payment hash: Test error/).to_stdout
        expect(parser.parse('{100 => 2}')).to be_nil
      end
    end
  end
end
