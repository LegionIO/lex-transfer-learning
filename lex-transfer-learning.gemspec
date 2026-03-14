# frozen_string_literal: true

require_relative 'lib/legion/extensions/transfer_learning/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-transfer-learning'
  spec.version       = Legion::Extensions::TransferLearning::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Transfer Learning'
  spec.description   = 'Domain knowledge transfer modeling for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-transfer-learning'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-transfer-learning'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-transfer-learning'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-transfer-learning'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-transfer-learning/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-transfer-learning.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
