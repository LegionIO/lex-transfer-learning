# lex-transfer-learning

Transfer learning domain modeling for LegionIO cognitive agents. Applies proficiency gained in one domain to related domains — with positive transfer for similar domains and interference for dissimilar ones.

## What It Does

`lex-transfer-learning` tracks domain knowledge proficiency and models how learning in one domain affects learning in another. Domains with similarity >= 0.6 produce positive transfer (proficiency boost). Domains with similarity < 0.3 produce interference (proficiency penalty). The neutral zone (0.3–0.59) has no transfer effect.

- **Proficiency**: 0.0–1.0 per domain; labels: novice, beginner, intermediate, advanced, expert
- **Positive transfer**: similarity >= 0.6 applies +0.15 proficiency boost to target
- **Interference**: similarity < 0.3 applies -0.1 proficiency penalty to target
- **Similarity index**: pairwise similarity scores between domains (explicitly set)
- **Transfer history**: each domain tracks transfer events received

## Usage

```ruby
require 'legion/extensions/transfer_learning'

client = Legion::Extensions::TransferLearning::Client.new

# Register domains
result_a = client.learn_domain(name: 'ruby', amount: 0.5)
domain_ruby = result_a[:domain_id]

result_b = client.learn_domain(name: 'python', amount: 0.1)
domain_python = result_b[:domain_id]

# Set similarity between domains
client.set_similarity(
  domain_a_id: domain_ruby,
  domain_b_id: domain_python,
  similarity: 0.7
)

# Check transfer effectiveness before applying
client.transfer_effectiveness(source_id: domain_ruby, target_id: domain_python)
# => { similarity: 0.7, transfer_label: :strong_positive }

# Apply transfer
client.attempt_transfer(source_id: domain_ruby, target_id: domain_python)
# => { transfer_type: :positive, effect: 0.15, similarity: 0.7 }
# python proficiency increased by 0.15

# Find what transfers best from ruby
client.most_transferable(domain_id: domain_ruby, limit: 5)

# Find what could interfere
client.interference_risks(domain_id: domain_ruby, limit: 5)

# Domain details
client.get_domain(domain_id: domain_python)
# => { proficiency: 0.25, label: :beginner, transfer_count: 1 }

# Transfer report
client.transfer_report
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
