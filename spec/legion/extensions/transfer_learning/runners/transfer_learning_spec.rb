# frozen_string_literal: true

require 'legion/extensions/transfer_learning/client'

RSpec.describe Legion::Extensions::TransferLearning::Runners::TransferLearning do
  let(:client) { Legion::Extensions::TransferLearning::Client.new }

  describe '#learn_domain' do
    it 'returns domain knowledge hash' do
      result = client.learn_domain(domain: :ruby, amount: 0.5)
      expect(result[:domain]).to eq(:ruby)
      expect(result[:proficiency]).to eq(0.5)
    end

    it 'accumulates proficiency across calls' do
      client.learn_domain(domain: :ruby, amount: 0.3)
      result = client.learn_domain(domain: :ruby, amount: 0.3)
      expect(result[:proficiency]).to be_within(0.0001).of(0.6)
    end
  end

  describe '#set_similarity' do
    it 'returns similarity hash' do
      result = client.set_similarity(domain_a: :ruby, domain_b: :python, similarity: 0.7)
      expect(result[:domain_a]).to eq(:ruby)
      expect(result[:domain_b]).to eq(:python)
      expect(result[:similarity]).to eq(0.7)
    end
  end

  describe '#attempt_transfer' do
    before do
      client.learn_domain(domain: :ruby, amount: 0.8)
      client.set_similarity(domain_a: :ruby, domain_b: :python, similarity: 0.8)
    end

    it 'returns ok status for known source' do
      result = client.attempt_transfer(from_domain: :ruby, to_domain: :python)
      expect(result[:status]).to eq(:ok)
    end

    it 'returns positive type for high similarity' do
      result = client.attempt_transfer(from_domain: :ruby, to_domain: :python)
      expect(result[:type]).to eq(:positive)
    end

    it 'returns source_not_found for unknown source' do
      result = client.attempt_transfer(from_domain: :unknown, to_domain: :python)
      expect(result[:status]).to eq(:source_not_found)
    end

    it 'includes proficiency in response' do
      result = client.attempt_transfer(from_domain: :ruby, to_domain: :python)
      expect(result).to have_key(:proficiency)
    end
  end

  describe '#transfer_effectiveness' do
    before do
      client.learn_domain(domain: :a, amount: 0.6)
      client.learn_domain(domain: :b, amount: 0.4)
      client.set_similarity(domain_a: :a, domain_b: :b, similarity: 0.7)
    end

    it 'returns effectiveness details' do
      result = client.transfer_effectiveness(from_domain: :a, to_domain: :b)
      expect(result[:type]).to eq(:positive)
      expect(result[:type_label]).to eq('positive')
      expect(result[:distance_label]).to eq('near')
    end
  end

  describe '#most_transferable' do
    before do
      client.learn_domain(domain: :target, amount: 0.2)
      client.learn_domain(domain: :good_source, amount: 0.8)
      client.set_similarity(domain_a: :good_source, domain_b: :target, similarity: 0.9)
    end

    it 'returns candidates hash' do
      result = client.most_transferable(target_domain: :target)
      expect(result[:target_domain]).to eq(:target)
      expect(result[:candidates]).to be_an(Array)
      expect(result[:count]).to eq(result[:candidates].size)
    end

    it 'includes positive transfer candidates' do
      result = client.most_transferable(target_domain: :target)
      expect(result[:candidates].map { |c| c[:domain] }).to include(:good_source)
    end
  end

  describe '#interference_risks' do
    before do
      client.learn_domain(domain: :target, amount: 0.3)
      client.learn_domain(domain: :risky_source, amount: 0.8)
      client.set_similarity(domain_a: :risky_source, domain_b: :target, similarity: 0.4)
    end

    it 'returns risks hash' do
      result = client.interference_risks(target_domain: :target)
      expect(result[:target_domain]).to eq(:target)
      expect(result[:risks]).to be_an(Array)
      expect(result[:count]).to eq(result[:risks].size)
    end

    it 'identifies interference risks' do
      result = client.interference_risks(target_domain: :target)
      expect(result[:risks].map { |r| r[:domain] }).to include(:risky_source)
    end
  end

  describe '#transfer_report' do
    it 'returns a report hash' do
      result = client.transfer_report
      expect(result).to have_key(:total_transfers)
      expect(result).to have_key(:domain_count)
    end

    it 'counts transfers after attempts' do
      client.learn_domain(domain: :a, amount: 0.8)
      client.set_similarity(domain_a: :a, domain_b: :b, similarity: 0.7)
      client.attempt_transfer(from_domain: :a, to_domain: :b)
      result = client.transfer_report
      expect(result[:total_transfers]).to eq(1)
      expect(result[:positive_transfers]).to eq(1)
    end
  end

  describe '#get_domain' do
    it 'returns found: false for unknown domain' do
      result = client.get_domain(domain: :unknown)
      expect(result[:found]).to be false
      expect(result[:domain]).to eq(:unknown)
    end

    it 'returns found: true for known domain' do
      client.learn_domain(domain: :ruby, amount: 0.5)
      result = client.get_domain(domain: :ruby)
      expect(result[:found]).to be true
      expect(result[:domain][:domain]).to eq(:ruby)
    end
  end
end
