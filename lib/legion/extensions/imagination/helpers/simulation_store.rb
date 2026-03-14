# frozen_string_literal: true

module Legion
  module Extensions
    module Imagination
      module Helpers
        class SimulationStore
          attr_reader :simulations

          def initialize
            @simulations = []
          end

          def store(simulation)
            @simulations << simulation
            @simulations = @simulations.last(Constants::MAX_SIMULATIONS)
            simulation
          end

          def get(simulation_id)
            @simulations.find { |s| s[:simulation_id] == simulation_id }
          end

          def recent(limit: 10)
            @simulations.last(limit)
          end

          def by_mode(mode)
            @simulations.select { |s| s[:mode] == mode }
          end

          def best_decisions
            @simulations.select { |s| s[:recommendation] }
                        .sort_by { |s| -(s.dig(:recommendation, :composite) || 0) }
          end

          def accuracy_check(simulation_id, actual_outcome:)
            sim = get(simulation_id)
            return nil unless sim

            sim[:actual_outcome] = actual_outcome
            sim[:accurate] = outcome_matches?(sim, actual_outcome)
            sim[:accurate]
          end

          def simulation_accuracy
            checked = @simulations.select { |s| s.key?(:accurate) }
            return nil if checked.empty?

            correct = checked.count { |s| s[:accurate] }
            correct.to_f / checked.size
          end

          def size
            @simulations.size
          end

          def clear
            @simulations.clear
          end

          private

          def outcome_matches?(simulation, actual)
            recommended = simulation.dig(:recommendation, :action)
            return false unless recommended

            actual_valence = actual[:valence] || :neutral
            positive_outcomes = %i[very_positive positive]
            positive_outcomes.include?(actual_valence)
          end
        end
      end
    end
  end
end
