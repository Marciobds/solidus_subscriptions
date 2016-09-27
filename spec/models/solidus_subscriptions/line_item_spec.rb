require 'rails_helper'

RSpec.describe SolidusSubscriptions::LineItem, type: :model do
  it { is_expected.to belong_to :spree_line_item }
  it { is_expected.to belong_to :subscription }
  it { is_expected.to have_one :order }

  it { is_expected.to validate_presence_of :spree_line_item }
  it { is_expected.to validate_presence_of :subscribable_id }

  it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
  it { is_expected.to validate_numericality_of(:interval_length).is_greater_than(0) }
  it { is_expected.to validate_numericality_of(:max_installments).is_greater_than(0) }
  it { is_expected.to validate_numericality_of(:max_installments).allow_nil }

  describe "#interval" do
    let(:line_item) { create :subscription_line_item, :with_subscription }
    before do
      Timecop.freeze(Date.parse("2016-09-22"))
      line_item.subscription.update!(actionable_date: Date.today)
    end
    after { Timecop.return }

    subject { line_item.interval }

    it { is_expected.to be_a ActiveSupport::Duration }
    it "calculates the duration correctly" do
      expect(subject.from_now).to eq Date.parse("2016-10-22")
    end
  end

  describe '#name' do
    subject { line_item.name }

    let(:line_item) do
      create(
        :subscription_line_item,
        :with_subscription,
        subscribable_id: variant.id
      )
    end

    let(:variant) { create :variant, subscribable: true }

    it 'is the name of the fulfilling variant' do
      expect(subject).to eq variant.name
    end
  end

  describe '#price' do
    subject { line_item.price }

    let(:variant) { create :variant, subscribable: true }
    let(:line_item) do
      create(
        :subscription_line_item,
        :with_subscription,
        subscribable_id: variant.id
      )
    end

    it 'is the price of the fulfilling variant' do
      expect(subject).to eq variant.price
    end
  end

  describe '#next_actionable_date' do
    subject { line_item.next_actionable_date }

    around { |e| Timecop.freeze { e.run } }

    let(:line_item) { create(:subscription_line_item, :with_subscription) }
    let(:expected_date) { Time.zone.now + line_item.interval }

    it { is_expected.to eq expected_date }
  end

  describe '#as_json' do
    subject { line_item.as_json }

    around { |e| Timecop.freeze { e.run } }
    let(:line_item) { create(:subscription_line_item, :with_subscription) }

    let(:expected_hash) do
      {
        "id" => line_item.id,
        "spree_line_item_id" => line_item.spree_line_item.id,
        "subscription_id" => line_item.subscription_id,
        "quantity" => line_item.quantity,
        "max_installments" => line_item.max_installments,
        "subscribable_id" => line_item.subscribable_id,
        "created_at" => line_item.created_at,
        "updated_at" => line_item.updated_at,
        "interval_units" => line_item.interval_units,
        "interval_length" => line_item.interval_length,
        "price" => line_item.price.to_f,
        "next_actionable_date" => line_item.next_actionable_date,
        "name" => line_item.name
      }
    end

    it 'is the json reporesentation of the line item' do
      expect(subject).to eq(expected_hash)
    end
  end
end
