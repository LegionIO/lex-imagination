# frozen_string_literal: true

module Legion
  module Extensions
    module Imagination
      module Runners
        module Imagination
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def simulate(actions:, context: {}, mode: :prospective, risk_tolerance: :moderate, **)
            scenarios = actions.first(Helpers::Constants::MAX_SCENARIOS).map do |action|
              build_scenario(action, context)
            end

            scenarios.each { |s| s.evaluate(alignment: context[:alignment] || 0.5, novelty: context[:novelty] || 0.5) }

            ranked = rank_scenarios(scenarios, risk_tolerance)
            recommendation = ranked.first

            simulation = {
              simulation_id:  SecureRandom.uuid,
              mode:           mode.to_sym,
              scenarios:      scenarios.map(&:to_h),
              recommendation: recommendation ? format_recommendation(recommendation) : nil,
              risk_tolerance: risk_tolerance,
              simulated_at:   Time.now.utc
            }

            simulation_store.store(simulation)

            Legion::Logging.debug "[imagination] simulated #{scenarios.size} scenarios, " \
                                  "recommended=#{recommendation&.action || 'none'}"

            simulation
          end

          def what_if(action:, context: {}, depth: 1, **)
            actual_depth = [depth, Helpers::Constants::MAX_DEPTH].min
            scenario = build_scenario(action, context)
            chain = build_consequence_chain(scenario, actual_depth)
            scenario.evaluate

            Legion::Logging.debug "[imagination] what_if: action=#{action} depth=#{actual_depth} " \
                                  "ev=#{scenario.expected_value.round(2)}"

            {
              scenario:          scenario.to_h,
              consequence_chain: chain,
              depth:             actual_depth,
              overall_valence:   classify_chain_valence(chain)
            }
          end

          def compare(action_a:, action_b:, context: {}, **)
            scenario_a = build_scenario(action_a, context)
            scenario_b = build_scenario(action_b, context)
            scenario_a.evaluate
            scenario_b.evaluate

            winner = scenario_a.evaluation[:composite] >= scenario_b.evaluation[:composite] ? :a : :b
            margin = (scenario_a.evaluation[:composite] - scenario_b.evaluation[:composite]).abs

            Legion::Logging.debug "[imagination] compare: #{action_a} vs #{action_b} -> winner=#{winner} margin=#{margin.round(3)}"

            {
              scenario_a: scenario_a.to_h,
              scenario_b: scenario_b.to_h,
              winner:     winner,
              margin:     margin,
              decisive:   margin > 0.1
            }
          end

          def record_actual_outcome(simulation_id:, actual_outcome: {}, **)
            result = simulation_store.accuracy_check(simulation_id, actual_outcome: actual_outcome)
            if result.nil?
              { error: :not_found }
            else
              Legion::Logging.info "[imagination] outcome recorded: simulation=#{simulation_id} accurate=#{result}"
              { simulation_id: simulation_id, accurate: result, overall_accuracy: simulation_store.simulation_accuracy }
            end
          end

          def imagination_stats(**)
            {
              total_simulations: simulation_store.size,
              accuracy:          simulation_store.simulation_accuracy,
              by_mode:           mode_distribution,
              recent_count:      simulation_store.recent(limit: 10).size
            }
          end

          private

          def simulation_store
            @simulation_store ||= Helpers::SimulationStore.new
          end

          def build_scenario(action, context)
            scenario = Helpers::Scenario.new(action: action, context: context)

            scenario.add_outcome(type: :success, likelihood: estimate_success_likelihood(action, context),
                                 value: estimate_positive_value(context), description: "#{action} succeeds",
                                 reversible: true)

            scenario.add_outcome(type: :failure, likelihood: estimate_failure_likelihood(action, context),
                                 value: estimate_negative_value(context), description: "#{action} fails",
                                 reversible: context.fetch(:reversible, true))

            if context[:wildcard]
              scenario.add_outcome(type: :wildcard, likelihood: 0.1,
                                   value: context[:wildcard_value] || 0.0,
                                   description: context[:wildcard], reversible: true)
            end

            scenario
          end

          def estimate_success_likelihood(_action, context)
            base = 0.5
            base += 0.1 if context[:familiar]
            base += 0.1 if context[:alignment].is_a?(Numeric) && context[:alignment] > 0.6
            base -= 0.1 if context[:risky]
            base.clamp(0.1, 0.9)
          end

          def estimate_failure_likelihood(_action, context)
            1.0 - estimate_success_likelihood(nil, context)
          end

          def estimate_positive_value(context)
            (context[:positive_value] || 0.6).clamp(0.0, 1.0)
          end

          def estimate_negative_value(context)
            -(context[:negative_value] || 0.4).clamp(0.0, 1.0)
          end

          def rank_scenarios(scenarios, risk_tolerance)
            scenarios.sort_by do |s|
              composite = s.evaluation[:composite]
              risk_adjust = case risk_tolerance.to_sym
                            when :conservative then composite - (s.risk_score * 0.3)
                            when :aggressive   then composite + (s.expected_value * 0.2)
                            else composite
                            end
              -risk_adjust
            end
          end

          def format_recommendation(scenario)
            {
              action:         scenario.action,
              composite:      scenario.evaluation[:composite],
              expected_value: scenario.expected_value,
              risk:           scenario.risk_score,
              reversibility:  scenario.reversibility,
              confidence:     classify_confidence(scenario.evaluation[:composite])
            }
          end

          def classify_confidence(composite)
            if composite >= Helpers::Constants::HIGH_CONFIDENCE
              :high
            elsif composite >= Helpers::Constants::MEDIUM_CONFIDENCE
              :medium
            else
              :low
            end
          end

          def build_consequence_chain(scenario, depth)
            chain = [{ depth: 0, expected_value: scenario.expected_value, risk: scenario.risk_score }]

            depth.times do |d|
              prev = chain.last
              dampened_ev = prev[:expected_value] * 0.7
              dampened_risk = prev[:risk] * 0.8
              chain << { depth: d + 1, expected_value: dampened_ev, risk: dampened_risk }
            end

            chain
          end

          def classify_chain_valence(chain)
            total_ev = chain.sum { |c| c[:expected_value] }
            if total_ev > 0.3
              :positive_trajectory
            elsif total_ev < -0.3
              :negative_trajectory
            else
              :uncertain_trajectory
            end
          end

          def mode_distribution
            dist = Hash.new(0)
            simulation_store.simulations.each { |s| dist[s[:mode]] += 1 }
            dist
          end
        end
      end
    end
  end
end
