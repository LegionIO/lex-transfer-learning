# frozen_string_literal: true

RSpec.describe Legion::Extensions::TransferLearning::Helpers::Constants do
  subject(:mod) { described_class }

  it 'defines MAX_DOMAINS as 200' do
    expect(mod::MAX_DOMAINS).to eq(200)
  end

  it 'defines POSITIVE_TRANSFER_THRESHOLD as 0.6' do
    expect(mod::POSITIVE_TRANSFER_THRESHOLD).to eq(0.6)
  end

  it 'defines NEGATIVE_TRANSFER_THRESHOLD as 0.3' do
    expect(mod::NEGATIVE_TRANSFER_THRESHOLD).to eq(0.3)
  end

  it 'defines TRANSFER_BOOST as 0.15' do
    expect(mod::TRANSFER_BOOST).to eq(0.15)
  end

  it 'defines INTERFERENCE_PENALTY as 0.1' do
    expect(mod::INTERFERENCE_PENALTY).to eq(0.1)
  end

  it 'defines all four TRANSFER_LABELS' do
    expect(mod::TRANSFER_LABELS.keys).to contain_exactly(:positive, :neutral, :negative, :interference)
  end

  it 'defines all three DISTANCE_LABELS' do
    expect(mod::DISTANCE_LABELS.keys).to contain_exactly(:near, :moderate, :far)
  end

  it 'freezes TRANSFER_LABELS' do
    expect(mod::TRANSFER_LABELS).to be_frozen
  end

  it 'freezes DISTANCE_LABELS' do
    expect(mod::DISTANCE_LABELS).to be_frozen
  end
end
