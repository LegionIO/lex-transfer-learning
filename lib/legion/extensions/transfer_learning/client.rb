# frozen_string_literal: true

require 'legion/extensions/transfer_learning/helpers/constants'
require 'legion/extensions/transfer_learning/helpers/domain_knowledge'
require 'legion/extensions/transfer_learning/helpers/transfer_engine'
require 'legion/extensions/transfer_learning/runners/transfer_learning'

module Legion
  module Extensions
    module TransferLearning
      class Client
        include Runners::TransferLearning

        def initialize(**)
          @transfer_engine = Helpers::TransferEngine.new
        end

        private

        attr_reader :transfer_engine
      end
    end
  end
end
