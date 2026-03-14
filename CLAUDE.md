# lex-transfer-learning

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-transfer-learning`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::TransferLearning`

## Purpose

Models transfer learning between knowledge domains — applying what is learned in one domain to accelerate learning in a related domain. Two domains can have a pairwise similarity score; when attempting transfer, high similarity produces a positive transfer boost, low similarity produces interference (negative transfer). Supports domain proficiency tracking, similarity management, and interference risk identification.

## Gem Info

- **Gem name**: `lex-transfer-learning`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/transfer_learning/
  version.rb                            # VERSION = '0.1.0'
  helpers/
    constants.rb                        # thresholds, boost/penalty amounts, limits, labels
    domain_knowledge.rb                 # DomainKnowledge class — proficiency and transfer history
    transfer_engine.rb                  # TransferEngine class — domain store with similarity index
  runners/
    transfer_learning.rb                # Runners::TransferLearning module — all public runner methods
  client.rb                             # Client class including Runners::TransferLearning
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `MAX_DOMAINS` | 200 | Maximum tracked knowledge domains |
| `POSITIVE_TRANSFER_THRESHOLD` | 0.6 | Similarity above this triggers positive transfer |
| `NEGATIVE_TRANSFER_THRESHOLD` | 0.3 | Similarity below this triggers interference |
| `TRANSFER_BOOST` | 0.15 | Proficiency increase on positive transfer |
| `INTERFERENCE_PENALTY` | 0.1 | Proficiency decrease on interference |
| `TRANSFER_LABELS` | hash | Named transfer outcomes: `strong_positive`, `positive`, `neutral`, `interference`, `strong_interference` |
| `DISTANCE_LABELS` | hash | Named similarity tiers: `very_close`, `close`, `moderate`, `distant`, `very_distant` |

## Helpers

### `Helpers::DomainKnowledge`

Proficiency-tracked knowledge domain with transfer history.

- `initialize(id:, name:, proficiency: 0.0)` — transfer_history=[], transfer_count=0
- `learn!(amount:)` — increments proficiency by amount; clamps to 1.0
- `record_transfer!(source_domain:, type:, amount:)` — appends transfer record to history; increments transfer_count
- `apply_boost!(amount = TRANSFER_BOOST)` — increments proficiency by amount
- `apply_penalty!(amount = INTERFERENCE_PENALTY)` — decrements proficiency by amount; floors at 0.0
- `proficiency_label` — `:novice` (< 0.2), `:beginner` (< 0.4), `:intermediate` (< 0.6), `:advanced` (< 0.8), `:expert` (>= 0.8)

### `Helpers::TransferEngine`

Domain store with pairwise similarity index and transfer operations.

- `initialize` — domains hash keyed by domain id, similarities hash keyed by `"domain_a:domain_b"`
- `create_domain(name:, proficiency: 0.0)` — returns nil if at MAX_DOMAINS
- `learn(domain_id:, amount:)` — calls `domain.learn!`
- `attempt_transfer(source_id:, target_id:)` — looks up similarity; applies boost if >= POSITIVE_TRANSFER_THRESHOLD; applies penalty if < NEGATIVE_TRANSFER_THRESHOLD; neutral if between; records in both domains' histories; returns transfer type and effect
- `set_similarity(domain_a_id:, domain_b_id:, similarity:)` — stores similarity at normalized key (sorted ids) and its inverse
- `get_similarity(domain_a_id:, domain_b_id:)` — returns similarity float; nil if not set
- `transfer_effectiveness(source_id:, target_id:)` — returns similarity + transfer type label without applying anything
- `most_transferable(domain_id:, limit: 5)` — domains with highest similarity to given domain
- `interference_risks(domain_id:, limit: 5)` — domains with similarity below NEGATIVE_TRANSFER_THRESHOLD
- `transfer_report` — overall: total domains, total transfers, successful transfers, interference count
- `rewards_by_domain(domain_id)` — all domains similar to given domain

## Runners

All runners are in `Runners::TransferLearning`. The `Client` includes this module and owns a `TransferEngine` instance.

| Runner | Parameters | Returns |
|---|---|---|
| `learn_domain` | `name:, amount: 0.1, domain_id: nil` | `{ success:, domain_id:, name:, proficiency:, label: }` |
| `attempt_transfer` | `source_id:, target_id:` | `{ success:, source_id:, target_id:, transfer_type:, effect:, similarity: }` |
| `set_similarity` | `domain_a_id:, domain_b_id:, similarity:` | `{ success:, domain_a_id:, domain_b_id:, similarity: }` |
| `transfer_effectiveness` | `source_id:, target_id:` | `{ success:, similarity:, transfer_label: }` |
| `most_transferable` | `domain_id:, limit: 5` | `{ success:, domains:, count: }` |
| `interference_risks` | `domain_id:, limit: 5` | `{ success:, domains:, count: }` |
| `transfer_report` | (none) | Overall transfer statistics from `TransferEngine#transfer_report` |
| `get_domain` | `domain_id:` | `{ success:, domain_id:, name:, proficiency:, label:, transfer_count: }` |

## Integration Points

- **lex-semantic-memory**: domain knowledge here tracks proficiency; semantic memory stores conceptual definitions within domains; high proficiency domains are candidates for spreading activation seeding
- **lex-self-model**: self-model tracks capability competence per named capability; transfer-learning tracks domain proficiency; they are complementary — capability competence can be seeded from domain proficiency
- **lex-tick / lex-cortex**: `attempt_transfer` can be triggered when the agent enters a new domain related to one already mastered
- **lex-memory**: memory traces tagged with a high-proficiency domain can be preferentially retrieved in related domains (positive transfer at the memory level)

## Development Notes

- Similarity keys are stored sorted (`[a,b].sort.join(':')`) so `get_similarity(a, b)` and `get_similarity(b, a)` both work with a single stored value
- `attempt_transfer` is the only method that applies boost/penalty — `transfer_effectiveness` is read-only
- The similarity thresholds form three regions: `>= 0.6` positive, `0.3–0.59` neutral, `< 0.3` interference — the neutral zone prevents constant interference from vaguely related domains
- `most_transferable` and `interference_risks` require that similarity has been explicitly set — domains with no similarity record are not included in results
- `learn_domain` accepts both `name:` (for create-or-find) and `domain_id:` for direct updates to existing domains
