# frozen_string_literal: true

RSpec.describe Legion::Extensions::TransferLearning::Helpers::TransferEngine do
  subject(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts with empty domains' do
      expect(engine.domains).to be_empty
    end

    it 'starts with empty similarities' do
      expect(engine.similarities).to be_empty
    end

    it 'starts with empty transfer_history' do
      expect(engine.transfer_history).to be_empty
    end
  end

  describe '#set_similarity' do
    it 'stores similarity between two domains' do
      engine.set_similarity(domain_a: :ruby, domain_b: :python, similarity: 0.7)
      expect(engine.similarities['python:ruby']).to eq(0.7)
    end

    it 'is commutative (same key regardless of order)' do
      engine.set_similarity(domain_a: :ruby, domain_b: :python, similarity: 0.7)
      engine.set_similarity(domain_a: :python, domain_b: :ruby, similarity: 0.8)
      key = 'python:ruby'
      expect(engine.similarities[key]).to eq(0.8)
    end

    it 'clamps similarity to 0.0..1.0' do
      engine.set_similarity(domain_a: :a, domain_b: :b, similarity: 1.5)
      expect(engine.similarities['a:b']).to eq(1.0)
    end

    it 'clamps negative similarity to 0.0' do
      engine.set_similarity(domain_a: :a, domain_b: :b, similarity: -0.3)
      expect(engine.similarities['a:b']).to eq(0.0)
    end

    it 'returns the clamped similarity' do
      result = engine.set_similarity(domain_a: :a, domain_b: :b, similarity: 0.5)
      expect(result).to eq(0.5)
    end
  end

  describe '#learn_domain' do
    it 'creates and returns domain knowledge' do
      result = engine.learn_domain(domain: :ruby, amount: 0.4)
      expect(result[:domain]).to eq(:ruby)
      expect(result[:proficiency]).to eq(0.4)
    end

    it 'accumulates proficiency on repeated calls' do
      engine.learn_domain(domain: :ruby, amount: 0.3)
      result = engine.learn_domain(domain: :ruby, amount: 0.3)
      expect(result[:proficiency]).to be_within(0.0001).of(0.6)
    end

    it 'increments learn_count' do
      engine.learn_domain(domain: :ruby, amount: 0.1)
      result = engine.learn_domain(domain: :ruby, amount: 0.1)
      expect(result[:learn_count]).to eq(2)
    end

    it 'clamps amount before applying' do
      result = engine.learn_domain(domain: :ruby, amount: 5.0)
      expect(result[:proficiency]).to eq(1.0)
    end
  end

  describe '#attempt_transfer' do
    before do
      engine.learn_domain(domain: :ruby, amount: 0.8)
    end

    it 'returns source_not_found when source domain does not exist' do
      result = engine.attempt_transfer(from_domain: :unknown, to_domain: :python)
      expect(result[:status]).to eq(:source_not_found)
    end

    context 'with positive similarity' do
      before { engine.set_similarity(domain_a: :ruby, domain_b: :python, similarity: 0.8) }

      it 'returns status :ok' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :python)
        expect(result[:status]).to eq(:ok)
      end

      it 'classifies as positive transfer' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :python)
        expect(result[:type]).to eq(:positive)
      end

      it 'classifies distance as near' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :python)
        expect(result[:distance]).to eq(:near)
      end

      it 'boosts target proficiency' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :python)
        expect(result[:effect]).to be > 0
        expect(result[:proficiency]).to be > 0
      end

      it 'increments source transfer_count' do
        engine.attempt_transfer(from_domain: :ruby, to_domain: :python)
        expect(engine.domains[:ruby].transfer_count).to eq(1)
      end

      it 'records transfer in history' do
        engine.attempt_transfer(from_domain: :ruby, to_domain: :python)
        expect(engine.transfer_history.size).to eq(1)
        expect(engine.transfer_history.first[:type]).to eq(:positive)
      end
    end

    context 'with interference similarity (0.3..0.6)' do
      before { engine.set_similarity(domain_a: :ruby, domain_b: :cobol, similarity: 0.4) }

      it 'classifies as interference' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :cobol)
        expect(result[:type]).to eq(:interference)
      end

      it 'applies penalty to target' do
        engine.learn_domain(domain: :cobol, amount: 0.5)
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :cobol)
        expect(result[:effect]).to be < 0
      end

      it 'classifies distance as moderate' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :cobol)
        expect(result[:distance]).to eq(:moderate)
      end
    end

    context 'with low similarity (0.0..0.3)' do
      before { engine.set_similarity(domain_a: :ruby, domain_b: :sql, similarity: 0.1) }

      it 'classifies as negative transfer' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :sql)
        expect(result[:type]).to eq(:negative)
      end

      it 'applies zero effect (negative = no net change)' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :sql)
        expect(result[:effect]).to eq(0.0)
      end

      it 'classifies distance as far' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :sql)
        expect(result[:distance]).to eq(:far)
      end
    end

    context 'with zero similarity (unknown domains)' do
      it 'classifies as neutral transfer' do
        result = engine.attempt_transfer(from_domain: :ruby, to_domain: :haskell)
        expect(result[:type]).to eq(:neutral)
      end
    end
  end

  describe '#transfer_effectiveness' do
    before do
      engine.learn_domain(domain: :ruby, amount: 0.7)
      engine.learn_domain(domain: :python, amount: 0.3)
      engine.set_similarity(domain_a: :ruby, domain_b: :python, similarity: 0.75)
    end

    it 'returns effectiveness hash' do
      result = engine.transfer_effectiveness(from_domain: :ruby, to_domain: :python)
      expect(result[:type]).to eq(:positive)
      expect(result[:type_label]).to eq('positive')
      expect(result[:distance]).to eq(:near)
      expect(result[:similarity]).to eq(0.75)
    end

    it 'returns source and target proficiency' do
      result = engine.transfer_effectiveness(from_domain: :ruby, to_domain: :python)
      expect(result[:source_proficiency]).to eq(0.7)
      expect(result[:target_proficiency]).to eq(0.3)
    end

    it 'handles unknown domains gracefully' do
      result = engine.transfer_effectiveness(from_domain: :unknown_a, to_domain: :unknown_b)
      expect(result[:source_proficiency]).to eq(0.0)
      expect(result[:target_proficiency]).to eq(0.0)
    end
  end

  describe '#most_transferable' do
    before do
      engine.learn_domain(domain: :target, amount: 0.2)
      engine.learn_domain(domain: :high_sim, amount: 0.8)
      engine.learn_domain(domain: :low_sim, amount: 0.8)
      engine.learn_domain(domain: :no_sim, amount: 0.8)
      engine.set_similarity(domain_a: :high_sim, domain_b: :target, similarity: 0.9)
      engine.set_similarity(domain_a: :low_sim, domain_b: :target, similarity: 0.1)
    end

    it 'returns only positively transferable domains' do
      result = engine.most_transferable(target_domain: :target)
      expect(result.map { |r| r[:domain] }).to include(:high_sim)
      expect(result.map { |r| r[:domain] }).not_to include(:low_sim)
      expect(result.map { |r| r[:domain] }).not_to include(:no_sim)
    end

    it 'sorts by similarity descending' do
      engine.learn_domain(domain: :mid_sim, amount: 0.8)
      engine.set_similarity(domain_a: :mid_sim, domain_b: :target, similarity: 0.7)
      result = engine.most_transferable(target_domain: :target)
      sims = result.map { |r| r[:similarity] }
      expect(sims).to eq(sims.sort.reverse)
    end

    it 'respects the limit parameter' do
      5.times do |i|
        name = :"domain_#{i}"
        engine.learn_domain(domain: name, amount: 0.5)
        engine.set_similarity(domain_a: name, domain_b: :target, similarity: 0.7 + (i * 0.01))
      end
      result = engine.most_transferable(target_domain: :target, limit: 3)
      expect(result.size).to be <= 3
    end
  end

  describe '#interference_risks' do
    before do
      engine.learn_domain(domain: :target, amount: 0.3)
      engine.learn_domain(domain: :risky, amount: 0.8)
      engine.learn_domain(domain: :safe, amount: 0.8)
      engine.set_similarity(domain_a: :risky, domain_b: :target, similarity: 0.45)
      engine.set_similarity(domain_a: :safe, domain_b: :target, similarity: 0.8)
    end

    it 'returns only interference-type domains' do
      result = engine.interference_risks(target_domain: :target)
      domains = result.map { |r| r[:domain] }
      expect(domains).to include(:risky)
      expect(domains).not_to include(:safe)
    end

    it 'sorts by similarity descending' do
      engine.learn_domain(domain: :also_risky, amount: 0.5)
      engine.set_similarity(domain_a: :also_risky, domain_b: :target, similarity: 0.35)
      result = engine.interference_risks(target_domain: :target)
      sims = result.map { |r| r[:similarity] }
      expect(sims).to eq(sims.sort.reverse)
    end

    it 'returns empty array when no interference risks' do
      engine2 = described_class.new
      engine2.learn_domain(domain: :t, amount: 0.3)
      expect(engine2.interference_risks(target_domain: :t)).to be_empty
    end
  end

  describe '#transfer_report' do
    it 'returns zero counts for empty engine' do
      report = engine.transfer_report
      expect(report[:total_transfers]).to eq(0)
      expect(report[:domain_count]).to eq(0)
    end

    it 'counts transfers correctly' do
      engine.learn_domain(domain: :a, amount: 0.8)
      engine.set_similarity(domain_a: :a, domain_b: :b, similarity: 0.7)
      engine.attempt_transfer(from_domain: :a, to_domain: :b)
      engine.attempt_transfer(from_domain: :a, to_domain: :b)
      report = engine.transfer_report
      expect(report[:total_transfers]).to eq(2)
      expect(report[:positive_transfers]).to eq(2)
    end

    it 'counts interference events' do
      engine.learn_domain(domain: :a, amount: 0.8)
      engine.set_similarity(domain_a: :a, domain_b: :b, similarity: 0.4)
      engine.attempt_transfer(from_domain: :a, to_domain: :b)
      report = engine.transfer_report
      expect(report[:interference_events]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      keys = engine.to_h.keys
      expect(keys).to contain_exactly(:domains, :similarities, :transfer_history, :report)
    end

    it 'reflects current state' do
      engine.learn_domain(domain: :ruby, amount: 0.5)
      expect(engine.to_h[:domains].keys).to include(:ruby)
    end
  end
end
