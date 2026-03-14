# frozen_string_literal: true

module Legion
  module Extensions
    module Imagination
      module Helpers
        class Scenario
          attr_reader :scenario_id, :action, :context, :outcomes, :evaluation, :created_at

          def initialize(action:, context: {})
            @scenario_id = SecureRandom.uuid
            @action = action
            @context = context
            @outcomes = []
            @evaluation = nil
            @created_at = Time.now.utc
          end

          def add_outcome(outcome)
            @outcomes << {
              outcome_id:   SecureRandom.uuid,
              type:         outcome[:type] || :neutral,
              likelihood:   (outcome[:likelihood] || 0.5).clamp(0.0, 1.0),
              valence:      classify_valence(outcome[:value] || 0.0),
              value:        (outcome[:value] || 0.0).clamp(-1.0, 1.0),
              description:  outcome[:description],
              consequences: outcome[:consequences] || [],
              reversible:   outcome.fetch(:reversible, true)
            }
          end

          def expected_value
            return 0.0 if @outcomes.empty?

            @outcomes.sum { |o| o[:likelihood] * o[:value] }
          end

          def risk_score
            return 0.0 if @outcomes.empty?

            negative_outcomes = @outcomes.select { |o| o[:value].negative? }
            return 0.0 if negative_outcomes.empty?

            negative_outcomes.sum { |o| o[:likelihood] * o[:value].abs }
          end

          def best_outcome
            @outcomes.max_by { |o| o[:value] }
          end

          def worst_outcome
            @outcomes.min_by { |o| o[:value] }
          end

          def reversibility
            return 1.0 if @outcomes.empty?

            reversible_count = @outcomes.count { |o| o[:reversible] }
            reversible_count.to_f / @outcomes.size
          end

          def evaluate(weights: Constants::EVALUATION_WEIGHTS, alignment: 0.5, novelty: 0.5)
            @evaluation = {
              expected_value: expected_value,
              risk:           risk_score,
              reversibility:  reversibility,
              alignment:      alignment,
              novelty:        novelty,
              composite:      compute_composite(weights, alignment, novelty),
              evaluated_at:   Time.now.utc
            }
          end

          def to_h
            {
              scenario_id:    @scenario_id,
              action:         @action,
              context:        @context,
              outcomes:       @outcomes,
              expected_value: expected_value,
              risk_score:     risk_score,
              reversibility:  reversibility,
              evaluation:     @evaluation,
              created_at:     @created_at
            }
          end

          private

          def classify_valence(value)
            if value > 0.5
              :very_positive
            elsif value > 0.1
              :positive
            elsif value > -0.1
              :neutral
            elsif value > -0.5
              :negative
            else
              :very_negative
            end
          end

          def compute_composite(weights, alignment, novelty)
            ev_score = (expected_value + 1.0) / 2.0
            risk_penalty = 1.0 - risk_score
            rev_score = reversibility

            (weights[:expected_value] * ev_score) +
              (weights[:risk] * risk_penalty) +
              (weights[:reversibility] * rev_score) +
              (weights[:alignment] * alignment) +
              (weights[:novelty] * novelty)
          end
        end
      end
    end
  end
end
