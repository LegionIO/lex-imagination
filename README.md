# lex-imagination

Counterfactual simulation engine for the LegionIO brain-modeled agentic architecture.

Mental rehearsal of actions before committing. The agent imagines possible futures, evaluates outcomes, and chooses the best path forward. This is System 2 thinking — deliberate, effortful reasoning about what might happen.

## Key Concepts

- **Scenario Simulation**: Build multiple scenarios with success/failure/wildcard outcomes, each with likelihood, value, and reversibility
- **What-If Analysis**: Trace consequence chains to a configurable depth — "if I do X, then Y might happen, then Z..."
- **A/B Comparison**: Compare two actions head-to-head with composite scoring
- **Risk-Adjusted Ranking**: Conservative, moderate, and aggressive risk tolerance modes
- **Outcome Tracking**: Record actual outcomes to measure simulation accuracy over time

## Usage

```ruby
client = Legion::Extensions::Imagination::Client.new

# Simulate multiple possible actions
result = client.simulate(
  actions: ['deploy_hotfix', 'wait_for_review', 'rollback'],
  context: { familiar: true, alignment: 0.8, risky: false },
  risk_tolerance: :moderate
)
# => { recommendation: { action: 'deploy_hotfix', composite: 0.72, confidence: :high }, ... }

# Deep what-if analysis
result = client.what_if(action: 'merge_without_tests', context: { risky: true }, depth: 3)
# => { consequence_chain: [...], overall_valence: :negative_trajectory }

# Compare two specific options
result = client.compare(action_a: 'refactor_first', action_b: 'ship_now', context: {})
# => { winner: :a, margin: 0.15, decisive: true }
```

## License

MIT
