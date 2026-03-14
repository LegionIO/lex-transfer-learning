# frozen_string_literal: true

RSpec.describe Legion::Extensions::TransferLearning::Helpers::DomainKnowledge do
  subject(:dk) { described_class.new(domain: :ruby) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(dk.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets domain' do
      expect(dk.domain).to eq(:ruby)
    end

    it 'starts proficiency at 0.0' do
      expect(dk.proficiency).to eq(0.0)
    end

    it 'starts learn_count at 0' do
      expect(dk.learn_count).to eq(0)
    end

    it 'starts transfer_count at 0' do
      expect(dk.transfer_count).to eq(0)
    end
  end

  describe '#learn!' do
    it 'increases proficiency by amount' do
      dk.learn!(amount: 0.3)
      expect(dk.proficiency).to eq(0.3)
    end

    it 'increments learn_count' do
      dk.learn!(amount: 0.1)
      expect(dk.learn_count).to eq(1)
    end

    it 'clamps proficiency at 1.0' do
      dk.learn!(amount: 1.5)
      expect(dk.proficiency).to eq(1.0)
    end

    it 'clamps proficiency at 0.0 for negative amount' do
      dk.learn!(amount: -0.5)
      expect(dk.proficiency).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(dk.learn!(amount: 0.1)).to be(dk)
    end
  end

  describe '#record_transfer!' do
    it 'increments transfer_count' do
      dk.record_transfer!
      expect(dk.transfer_count).to eq(1)
    end

    it 'returns self' do
      expect(dk.record_transfer!).to be(dk)
    end
  end

  describe '#apply_boost!' do
    it 'increases proficiency' do
      dk.learn!(amount: 0.5)
      dk.apply_boost!(0.2)
      expect(dk.proficiency).to be_within(0.0001).of(0.7)
    end

    it 'clamps at 1.0' do
      dk.learn!(amount: 0.9)
      dk.apply_boost!(0.5)
      expect(dk.proficiency).to eq(1.0)
    end
  end

  describe '#apply_penalty!' do
    it 'decreases proficiency' do
      dk.learn!(amount: 0.5)
      dk.apply_penalty!(0.2)
      expect(dk.proficiency).to be_within(0.0001).of(0.3)
    end

    it 'clamps at 0.0' do
      dk.apply_penalty!(0.5)
      expect(dk.proficiency).to eq(0.0)
    end
  end

  describe '#proficiency_label' do
    it 'returns novice for 0.0' do
      expect(dk.proficiency_label).to eq('novice')
    end

    it 'returns beginner for 0.3' do
      dk.learn!(amount: 0.3)
      expect(dk.proficiency_label).to eq('beginner')
    end

    it 'returns intermediate for 0.5' do
      dk.learn!(amount: 0.5)
      expect(dk.proficiency_label).to eq('intermediate')
    end

    it 'returns advanced for 0.7' do
      dk.learn!(amount: 0.7)
      expect(dk.proficiency_label).to eq('advanced')
    end

    it 'returns expert for 0.9' do
      dk.learn!(amount: 0.9)
      expect(dk.proficiency_label).to eq('expert')
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      hash = dk.to_h
      expect(hash.keys).to contain_exactly(:id, :domain, :proficiency, :proficiency_label, :learn_count, :transfer_count)
    end

    it 'reflects current proficiency' do
      dk.learn!(amount: 0.4)
      expect(dk.to_h[:proficiency]).to eq(0.4)
    end

    it 'includes proficiency_label' do
      dk.learn!(amount: 0.4)
      expect(dk.to_h[:proficiency_label]).to eq('intermediate')
    end
  end
end
