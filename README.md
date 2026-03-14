# lex-imagination

Counterfactual simulation and mental rehearsal for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-imagination` lets an agent mentally rehearse actions before committing to them. Given a list of candidate actions, it builds scenarios with success, failure, and wildcard outcomes, evaluates each via a weighted composite score (expected value, risk, reversibility, novelty, alignment), and returns a ranked recommendation. Deep what-if chains trace consequences recursively. Actual outcomes can be recorded to track simulation accuracy over time.

Key capabilities:

- **Multi-scenario simulation**: evaluate up to 5 candidate actions per call
- **Composite scoring**: expected value (35%), risk (25%), reversibility (20%), novelty (10%), alignment (10%)
- **Recursive what-if chains**: trace consequences up to depth 3
- **Head-to-head comparison**: compare two actions directly
- **Outcome tracking**: record actual results to measure simulation accuracy

## Installation

Add to your Gemfile:

```ruby
gem 'lex-imagination'
```

Or install directly:

```
gem install lex-imagination
```

## Usage

```ruby
require 'legion/extensions/imagination'

client = Legion::Extensions::Imagination::Client.new

# Simulate candidate actions
result = client.simulate(
  actions: ['deploy_hotfix', 'wait_for_review', 'rollback'],
  context: { familiar: true, alignment: 0.8, risky: false },
  risk_tolerance: :moderate
)
# => { recommendation: { action: 'deploy_hotfix', composite: 0.72, confidence: :high },
#      scenarios: [...], simulation_id: "..." }

# Deep what-if analysis
chain = client.what_if(action: 'merge_without_tests', context: { risky: true }, depth: 3)
# => { consequence_chain: [...], overall_valence: :negative_trajectory }

# Compare two options
comparison = client.compare(action_a: 'refactor_first', action_b: 'ship_now', context: {})
# => { winner: :a, margin: 0.15, decisive: true }

# Record what actually happened
client.record_actual_outcome(simulation_id: result[:simulation_id], actual_outcome: :success)

# Stats
client.imagination_stats
```

## Runner Methods

| Method | Description |
|---|---|
| `simulate` | Build and rank scenarios for a list of candidate actions |
| `what_if` | Recursive consequence chain for a single action |
| `compare` | Head-to-head composite score comparison of two actions |
| `record_actual_outcome` | Log actual result for accuracy tracking |
| `imagination_stats` | Total simulations, accuracy, avg composite |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
