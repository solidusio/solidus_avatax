require 'spec_helper'

describe Spree::Calculator::Avatax do
  let(:calculator) { Spree::Calculator::Avatax.new }

  describe '.description' do
    it 'should not be nil' do
      expect(Spree::Calculator::Avatax.description).to eq Spree.t(:avatax_description)
    end
  end

  describe '#compute' do
    it 'should raise DoNotUseCompute' do
      lambda {
        calculator.compute(nil)
      }.should raise_error(Spree::Calculator::Avatax::DoNotUseCompute)
    end
  end

end
