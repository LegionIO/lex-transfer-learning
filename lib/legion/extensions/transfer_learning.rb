# frozen_string_literal: true

require 'legion/extensions/transfer_learning/version'
require 'legion/extensions/transfer_learning/helpers/constants'
require 'legion/extensions/transfer_learning/helpers/domain_knowledge'
require 'legion/extensions/transfer_learning/helpers/transfer_engine'
require 'legion/extensions/transfer_learning/runners/transfer_learning'

module Legion
  module Extensions
    module TransferLearning
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
