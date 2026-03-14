# frozen_string_literal: true

RSpec.describe Legion::Extensions::Imagination::Helpers::SimulationStore do
  subject(:store) { described_class.new }

  let(:simulation) do
    {
      simulation_id:  SecureRandom.uuid,
      mode:           :prospective,
      scenarios:      [],
      recommendation: { action: 'deploy', composite: 0.8 },
      simulated_at:   Time.now.utc
    }
  end

  describe '#store' do
    it 'stores a simulation' do
      store.store(simulation)
      expect(store.size).to eq(1)
    end

    it 'caps at MAX_SIMULATIONS' do
      (Legion::Extensions::Imagination::Helpers::Constants::MAX_SIMULATIONS + 5).times do |i|
        store.store(simulation.merge(simulation_id: "sim-#{i}"))
      end
      expect(store.size).to eq(Legion::Extensions::Imagination::Helpers::Constants::MAX_SIMULATIONS)
    end
  end

  describe '#get' do
    it 'retrieves by ID' do
      store.store(simulation)
      found = store.get(simulation[:simulation_id])
      expect(found).to eq(simulation)
    end

    it 'returns nil for missing ID' do
      expect(store.get('nonexistent')).to be_nil
    end
  end

  describe '#recent' do
    it 'returns last N simulations' do
      3.times { |i| store.store(simulation.merge(simulation_id: "sim-#{i}")) }
      expect(store.recent(limit: 2).size).to eq(2)
    end
  end

  describe '#by_mode' do
    it 'filters by mode' do
      store.store(simulation.merge(mode: :prospective))
      store.store(simulation.merge(simulation_id: 'x', mode: :counterfactual))
      expect(store.by_mode(:prospective).size).to eq(1)
    end
  end

  describe '#accuracy_check' do
    it 'records actual outcome' do
      store.store(simulation)
      result = store.accuracy_check(simulation[:simulation_id], actual_outcome: { valence: :positive })
      expect(result).to be true
    end

    it 'returns nil for missing simulation' do
      result = store.accuracy_check('nonexistent', actual_outcome: {})
      expect(result).to be_nil
    end
  end

  describe '#simulation_accuracy' do
    it 'returns nil with no checked simulations' do
      expect(store.simulation_accuracy).to be_nil
    end

    it 'computes accuracy' do
      store.store(simulation)
      store.accuracy_check(simulation[:simulation_id], actual_outcome: { valence: :positive })
      expect(store.simulation_accuracy).to eq(1.0)
    end
  end

  describe '#clear' do
    it 'removes all simulations' do
      store.store(simulation)
      store.clear
      expect(store.size).to eq(0)
    end
  end
end
