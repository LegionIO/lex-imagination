# frozen_string_literal: true

module Legion
  module Extensions
    module Imagination
      module Helpers
        module Constants
          # Maximum scenarios per simulation
          MAX_SCENARIOS = 5

          # Maximum simulation depth (chained consequence steps)
          MAX_DEPTH = 3

          # Simulation history capacity
          MAX_SIMULATIONS = 100

          # Confidence thresholds
          HIGH_CONFIDENCE   = 0.7
          MEDIUM_CONFIDENCE = 0.4
          LOW_CONFIDENCE    = 0.2

          # Outcome valence labels
          OUTCOME_VALENCES = %i[very_positive positive neutral negative very_negative].freeze

          # Risk tolerance levels
          RISK_TOLERANCES = %i[conservative moderate aggressive].freeze

          # Default evaluation weights
          EVALUATION_WEIGHTS = {
            expected_value: 0.3,
            risk:           0.25,
            reversibility:  0.2,
            alignment:      0.15,
            novelty:        0.1
          }.freeze

          # Scenario outcome types
          OUTCOME_TYPES = %i[success partial_success neutral partial_failure failure wildcard].freeze

          # Imagination modes
          MODES = %i[
            prospective
            retrospective
            counterfactual
            exploratory
          ].freeze
        end
      end
    end
  end
end
