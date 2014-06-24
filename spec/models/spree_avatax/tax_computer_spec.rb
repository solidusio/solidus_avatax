require 'spec_helper'

describe SpreeAvatax::TaxComputer do
  shared_examples "fetches new tax information" do
    before do
      Avalara.should_receive(:get_tax).and_return(double(tax_lines: order.line_items.map { |li| double(line_no: li.id.to_s, tax_calculated: 5.00) }))
    end

    it "stores the time in the status field of the order" do
      Timecop.freeze do
        expect { subject }.to change { order.send(status_field) }.to Time.now
      end
    end

    it "populates an adjustment" do
      subject
      order.line_items.each do |line_item|
        line_item.adjustments.tax.size.should == 1
        line_item.adjustments.each do |adjustment|
          adjustment.source.should_not be_nil
          adjustment.state.should == 'closed'
        end
      end
    end
  end

  shared_examples "does not fetch new tax information" do
    it "does not store the time in the status field of the order" do
      expect { subject }.not_to change { order.send(status_field) }
    end

    it "does not fetch taxes from avalara" do
      Avalara.should_receive(:get_tax).never
    end
  end

  describe '#reset_tax_attributes' do
    let(:order) { create(:order_with_line_items, additional_tax_total: 1, adjustment_total: 1, included_tax_total: 1) }
    let(:calculator) { SpreeAvatax::TaxComputer.new(order) }

    subject { calculator.reset_tax_attributes(order) }

    before do

      order.line_items.each do |line_item|
        line_item.adjustments.eligible.tax.additional.create!({
          adjustable: line_item,
          amount: 1.23,
          order: order,
          label: 'Previous Tax',
          included: false
        })

        line_item.update_attributes!(
          additional_tax_total: 1,
          adjustment_total: 1,
          pre_tax_amount: 1,
          included_tax_total: 1
        )
      end
    end

    it 'should remove all eligible tax adjustments' do
      subject
      order.line_items.map { |li| li.adjustments.tax.size }.sum.should == 0
    end

    it 'should remove tax adjustments even if they are not reachable through a line item anymore' do
      disassociated_adjustment = order.adjustments.eligible.tax.additional.create!({
        adjustable_type: 'Spree::LineItem',
        adjustable_id: 99999,
        amount: 6.66,
        order: order,
        label: 'Test',
        included: false
      })
      subject
      # make sure this got deleted
      expect { disassociated_adjustment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    [:additional_tax_total, :adjustment_total, :included_tax_total].each do |f|
      it "should 0 order #{f}" do
        subject
        order.send(f).should == 0
      end
    end

    [:additional_tax_total, :adjustment_total, :pre_tax_amount, :included_tax_total].each do |f|
      it "should 0 line_item #{f}" do
        subject
        order.line_items.map { |li| li.send(f) }.sum.should == 0
      end
    end
  end

  describe '#compute' do
    let(:params) { {} }
    let(:order) { create(:order_with_line_items) }
    let(:calculator) { SpreeAvatax::TaxComputer.new(order, params) }
    let(:status_field) { calculator.class::DEFAULT_STATUS_FIELD }
    let!(:tax_rate) { create :tax_rate, name: 'Avatax No Op' }

    subject { calculator.compute }

    context "configuration" do
      before { Spree::Order.any_instance.stub(:avataxable?).and_return(true) }

      context "order status field" do
        let(:status_field) { :avatax_invoice_at }
        let(:params) { {status_field: status_field} }
        subject { calculator.compute }
        include_examples "fetches new tax information"
      end

      context "the order is avataxable" do
        before { Spree::Order.any_instance.stub(:avataxable?).and_return(true) }
        include_examples "fetches new tax information"
      end

      context "the order is not avataxable" do
        before { Spree::Order.any_instance.stub(:avataxable?).and_return(false) }
        include_examples "does not fetch new tax information"
      end

      context "doc_type" do
        context "when it is foo" do
          let(:params) { {doc_type: 'foo'} }

          it "can be configured" do
            SpreeAvatax::Invoice.should_receive(:new).with do |o, doc_type|
              doc_type == "foo"
            end.and_call_original
            subject
          end
        end

        context "when it is DEFAULT_DOC_TYPE" do
          let(:params) { {doc_type: SpreeAvatax::TaxComputer::DEFAULT_DOC_TYPE} }

          it "has a default" do
            SpreeAvatax::Invoice.should_receive(:new).with do |o, doc_type|
              doc_type == SpreeAvatax::TaxComputer::DEFAULT_DOC_TYPE
            end.and_call_original
            subject
          end
        end
      end
    end

    context "avalara errors" do
      before do
        Spree::Order.any_instance.stub(:avataxable?).and_return(false)
        Avalara.stub(:get_tax).and_raise(Avalara::ApiError)
      end

      it "handles them gracefully" do
        order.send("#{status_field}=", 1.minute.ago)
        expect { calculator.logger.to_receive(:error).with(kind_of(Avalara::ApiError)) }
        expect { Honeybadger.to_receive(:notify).with(kind_of(Avalara::ApiError)) }
        expect { subject }.not_to raise_error
        expect(order.reload.send(status_field)).to be_nil
      end
    end
  end
end
