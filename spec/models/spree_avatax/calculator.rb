require 'spec_helper'

describe SpreeAvatax::Calculator do
  let(:calculator) { SpreeAvatax::Calculator.new }

  describe '.description' do
    it 'should not be nil' do
      expect(SpreeAvatax::Calculator.description).to eq Spree.t(:avatax_description)
    end
  end

  describe '#compute' do
    it 'should raise DoNotUseCompute' do
      lambda {
        calculator.compute(nil)
      }.should raise_error(SpreeAvatax::Calculator::DoNotUseCompute)
    end
  end

end
