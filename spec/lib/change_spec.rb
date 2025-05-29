# require 'spec_helper'

describe Change do
  describe '#change' do
    context 'give an item name & price' do
      it 'returns the item name' do
        change = Change.new(10.72)
        expect(change.amount).to eq(10.72)
      end
    end
  end
end
