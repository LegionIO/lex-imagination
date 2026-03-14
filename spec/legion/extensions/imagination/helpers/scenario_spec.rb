# frozen_string_literal: true

RSpec.describe Legion::Extensions::Imagination::Helpers::Scenario do
  subject(:scenario) { described_class.new(action: 'deploy', context: { env: :prod }) }

  describe '#initialize' do
    it 'assigns a UUID' do
      expect(scenario.scenario_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores action and context' do
      expect(scenario.action).to eq('deploy')
      expect(scenario.context[:env]).to eq(:prod)
    end
  end

  describe '#add_outcome' do
    it 'adds an outcome' do
      scenario.add_outcome(type: :success, likelihood: 0.7, value: 0.8)
      expect(scenario.outcomes.size).to eq(1)
      expect(scenario.outcomes.first[:type]).to eq(:success)
    end

    it 'clamps likelihood to 0-1' do
      scenario.add_outcome(likelihood: 1.5, value: 0.5)
      expect(scenario.outcomes.first[:likelihood]).to eq(1.0)
    end

    it 'classifies valence' do
      scenario.add_outcome(value: 0.8)
      expect(scenario.outcomes.first[:valence]).to eq(:very_positive)
    end
  end

  describe '#expected_value' do
    it 'returns 0 with no outcomes' do
      expect(scenario.expected_value).to eq(0.0)
    end

    it 'computes weighted expected value' do
      scenario.add_outcome(likelihood: 0.7, value: 0.8)
      scenario.add_outcome(likelihood: 0.3, value: -0.5)
      ev = scenario.expected_value
      expect(ev).to be_within(0.001).of((0.7 * 0.8) + (0.3 * -0.5))
    end
  end

  describe '#risk_score' do
    it 'returns 0 with no negative outcomes' do
      scenario.add_outcome(likelihood: 0.5, value: 0.5)
      expect(scenario.risk_score).to eq(0.0)
    end

    it 'computes risk from negative outcomes' do
      scenario.add_outcome(likelihood: 0.3, value: -0.6)
      expect(scenario.risk_score).to be_within(0.001).of(0.3 * 0.6)
    end
  end

  describe '#best_outcome / #worst_outcome' do
    before do
      scenario.add_outcome(value: 0.8, likelihood: 0.5)
      scenario.add_outcome(value: -0.3, likelihood: 0.5)
    end

    it 'returns highest value outcome as best' do
      expect(scenario.best_outcome[:value]).to eq(0.8)
    end

    it 'returns lowest value outcome as worst' do
      expect(scenario.worst_outcome[:value]).to eq(-0.3)
    end
  end

  describe '#reversibility' do
    it 'returns 1.0 when all outcomes are reversible' do
      scenario.add_outcome(value: 0.5, reversible: true)
      expect(scenario.reversibility).to eq(1.0)
    end

    it 'returns 0.0 when no outcomes are reversible' do
      scenario.add_outcome(value: 0.5, reversible: false)
      expect(scenario.reversibility).to eq(0.0)
    end
  end

  describe '#evaluate' do
    before do
      scenario.add_outcome(likelihood: 0.7, value: 0.6)
      scenario.add_outcome(likelihood: 0.3, value: -0.3)
    end

    it 'produces evaluation hash' do
      scenario.evaluate
      expect(scenario.evaluation).to include(:expected_value, :risk, :reversibility, :composite)
    end

    it 'produces a composite score' do
      scenario.evaluate
      expect(scenario.evaluation[:composite]).to be_a(Numeric)
      expect(scenario.evaluation[:composite]).to be > 0
    end
  end

  describe '#to_h' do
    it 'returns complete scenario hash' do
      h = scenario.to_h
      expect(h).to include(:scenario_id, :action, :context, :outcomes, :expected_value)
    end
  end
end
