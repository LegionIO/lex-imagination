# frozen_string_literal: true

RSpec.describe Legion::Extensions::Imagination::Runners::Imagination do
  let(:client) { Legion::Extensions::Imagination::Client.new }

  describe '#simulate' do
    it 'simulates multiple actions' do
      result = client.simulate(actions: %w[deploy rollback wait])
      expect(result[:scenarios].size).to eq(3)
      expect(result).to have_key(:recommendation)
    end

    it 'limits to MAX_SCENARIOS' do
      actions = (1..10).map { |i| "action_#{i}" }
      result = client.simulate(actions: actions)
      expect(result[:scenarios].size).to be <= Legion::Extensions::Imagination::Helpers::Constants::MAX_SCENARIOS
    end

    it 'stores simulation in history' do
      client.simulate(actions: %w[deploy])
      expect(client.simulation_store.size).to eq(1)
    end

    it 'recommends the best action' do
      result = client.simulate(
        actions:        %w[safe_action risky_action],
        context:        { familiar: true, alignment: 0.8 },
        risk_tolerance: :conservative
      )
      expect(result[:recommendation]).to have_key(:action)
      expect(result[:recommendation]).to have_key(:composite)
    end

    it 'respects risk tolerance' do
      conservative = client.simulate(actions: %w[deploy], risk_tolerance: :conservative)
      aggressive = client.simulate(actions: %w[deploy], risk_tolerance: :aggressive)
      expect(conservative[:recommendation]).not_to be_nil
      expect(aggressive[:recommendation]).not_to be_nil
    end
  end

  describe '#what_if' do
    it 'returns scenario with consequence chain' do
      result = client.what_if(action: 'merge_without_tests', depth: 2)
      expect(result[:consequence_chain].size).to eq(3)
      expect(result[:depth]).to eq(2)
    end

    it 'limits depth to MAX_DEPTH' do
      result = client.what_if(action: 'test', depth: 100)
      expect(result[:depth]).to eq(Legion::Extensions::Imagination::Helpers::Constants::MAX_DEPTH)
    end

    it 'returns overall valence' do
      result = client.what_if(action: 'safe_deploy', context: { familiar: true })
      expect(result[:overall_valence]).to be_a(Symbol)
    end
  end

  describe '#compare' do
    it 'compares two actions' do
      result = client.compare(action_a: 'refactor', action_b: 'ship_now')
      expect(%i[a b]).to include(result[:winner])
      expect(result).to have_key(:margin)
      expect(result).to have_key(:decisive)
    end

    it 'returns scenario details for both' do
      result = client.compare(action_a: 'a', action_b: 'b')
      expect(result[:scenario_a]).to have_key(:expected_value)
      expect(result[:scenario_b]).to have_key(:expected_value)
    end
  end

  describe '#record_actual_outcome' do
    it 'records outcome for existing simulation' do
      sim = client.simulate(actions: %w[deploy])
      result = client.record_actual_outcome(
        simulation_id:  sim[:simulation_id],
        actual_outcome: { valence: :positive }
      )
      expect(result[:accurate]).not_to be_nil
    end

    it 'returns error for missing simulation' do
      result = client.record_actual_outcome(simulation_id: 'nonexistent', actual_outcome: {})
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#imagination_stats' do
    it 'returns stats summary' do
      client.simulate(actions: %w[deploy])
      result = client.imagination_stats
      expect(result[:total_simulations]).to eq(1)
      expect(result).to have_key(:by_mode)
    end
  end
end
