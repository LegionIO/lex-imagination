# lex-imagination

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-imagination`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Imagination`

## Purpose

Counterfactual simulation and mental rehearsal for LegionIO agents. Builds multi-outcome scenarios for candidate actions, evaluates them via a weighted composite score, supports recursive what-if consequence chains, and compares action pairs head-to-head. Records actual outcomes to track simulation accuracy over time.

## Gem Info

- **Require path**: `legion/extensions/imagination`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/imagination/
  version.rb
  helpers/
    constants.rb          # Limits, weights, modes
    scenario.rb           # Scenario value object with outcome scoring
    simulation_store.rb   # In-memory simulation registry + accuracy tracking
  runners/
    imagination.rb        # Runner module

spec/
  legion/extensions/imagination/
    helpers/
      constants_spec.rb
      scenario_spec.rb
      simulation_store_spec.rb
    runners/imagination_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
MAX_SCENARIOS    = 5     # maximum scenarios per simulate call
MAX_DEPTH        = 3     # maximum what-if consequence chain depth
MAX_SIMULATIONS  = 100   # total stored simulations (LRU eviction)
HIGH_CONFIDENCE  = 0.7

EVALUATION_WEIGHTS = {
  expected_value: 0.35,
  risk_score:     0.25,
  reversibility:  0.20,
  novelty:        0.10,
  alignment:      0.10
}

MODES = %i[prospective retrospective counterfactual exploratory]
```

## Helpers

### `Helpers::Scenario` (class)

Value object representing one simulated action and its possible outcomes.

| Attribute | Type | Description |
|---|---|---|
| `action` | String | the candidate action being simulated |
| `outcomes` | Array<Hash> | success/failure/wildcard outcomes with likelihood, value, reversibility |
| `context` | Hash | simulation context (familiar, alignment, risky flags) |
| `mode` | Symbol | one of MODES |

Key methods:

| Method | Description |
|---|---|
| `add_outcome(type:, likelihood:, value:, reversibility:)` | appends to outcomes array |
| `expected_value` | probability-weighted average value across outcomes |
| `risk_score` | weighted variance / downside probability |
| `reversibility` | average reversibility across outcomes |
| `evaluate(weights, alignment, novelty)` | computes composite score using EVALUATION_WEIGHTS |

### `Helpers::SimulationStore` (class)

Registry of completed simulations with accuracy tracking.

| Method | Description |
|---|---|
| `store(simulation)` | persists a simulation; evicts oldest when over MAX_SIMULATIONS |
| `get(id)` | retrieve by ID |
| `recent(limit:)` | most recent N simulations |
| `accuracy_check(id:, actual_outcome:)` | records actual outcome against predicted; updates accuracy |
| `simulation_accuracy` | overall accuracy ratio for stored simulations |

## Runners

Module: `Legion::Extensions::Imagination::Runners::Imagination`

Private state: `@store` (memoized `SimulationStore` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `simulate` | `actions:, context: {}, risk_tolerance: :moderate` | Build scenarios for each action, evaluate, return ranked recommendation |
| `what_if` | `action:, context: {}, depth: MAX_DEPTH` | Recursive consequence chain up to depth levels |
| `compare` | `action_a:, action_b:, context: {}` | Head-to-head composite score comparison |
| `record_actual_outcome` | `simulation_id:, actual_outcome:` | Log what actually happened for accuracy tracking |
| `imagination_stats` | (none) | Total simulations, accuracy, scenario count, avg composite |

`simulate` return structure:
```ruby
{
  recommendation: { action: String, composite: Float, confidence: :high/:moderate/:low },
  scenarios: [ { action:, composite:, expected_value:, risk_score: }, ... ],
  simulation_id: String
}
```

`what_if` return structure:
```ruby
{
  action: String,
  depth: Integer,
  consequence_chain: [ { depth:, scenario:, expected_value: }, ... ],
  overall_valence: :positive_trajectory | :negative_trajectory | :neutral
}
```

## Integration Points

- **lex-tick**: imagination is wired into the `action_selection` phase; `simulate` is called with candidate actions derived from goals/volition before execution.
- **lex-goal-management**: candidate actions come from active goals; simulation composite score biases which goal receives focus.
- **lex-risk** (if present): risk_score from scenarios feeds external risk register.
- **lex-metacognition**: `Imagination` is listed under `:cognition` capability category.

## Development Notes

- Scenario outcomes are generated synthetically from the context hash (familiar, alignment, risky flags) — there is no LLM call in the current implementation. Actual outcome generation logic is in the Scenario class initializer based on context.
- `what_if` recursively calls itself up to `depth` levels with diminishing confidence each level. The consequence chain is breadth-first at each depth level for the top scenario only (most likely outcome path).
- `risk_tolerance` affects the composite score weighting: `:conservative` boosts `reversibility` weight, `:aggressive` boosts `expected_value`, `:moderate` uses EVALUATION_WEIGHTS as-is.
- `simulation_accuracy` requires `record_actual_outcome` to be called; without it, accuracy returns nil.
- MAX_SIMULATIONS eviction is LRU by insertion time, not accuracy. Accurate but old simulations are evicted like any other.
