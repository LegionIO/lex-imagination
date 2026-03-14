# frozen_string_literal: true

RSpec.describe Legion::Extensions::Imagination::Helpers::Constants do
  it 'defines 4 imagination modes' do
    expect(described_class::MODES.size).to eq(4)
  end

  it 'defines 6 outcome types' do
    expect(described_class::OUTCOME_TYPES.size).to eq(6)
  end

  it 'defines 3 risk tolerances' do
    expect(described_class::RISK_TOLERANCES).to contain_exactly(:conservative, :moderate, :aggressive)
  end

  it 'defines evaluation weights summing to 1.0' do
    total = described_class::EVALUATION_WEIGHTS.values.sum
    expect(total).to be_within(0.001).of(1.0)
  end

  it 'defines ordered confidence thresholds' do
    expect(described_class::LOW_CONFIDENCE).to be < described_class::MEDIUM_CONFIDENCE
    expect(described_class::MEDIUM_CONFIDENCE).to be < described_class::HIGH_CONFIDENCE
  end
end
