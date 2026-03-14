# frozen_string_literal: true

module Legion
  module Extensions
    module TransferLearning
      module Helpers
        module Constants
          MAX_DOMAINS                  = 200
          POSITIVE_TRANSFER_THRESHOLD  = 0.6
          NEGATIVE_TRANSFER_THRESHOLD  = 0.3
          TRANSFER_BOOST               = 0.15
          INTERFERENCE_PENALTY         = 0.1

          TRANSFER_LABELS = {
            positive:     'positive',
            neutral:      'neutral',
            negative:     'negative',
            interference: 'interference'
          }.freeze

          DISTANCE_LABELS = {
            near:     'near',
            moderate: 'moderate',
            far:      'far'
          }.freeze
        end
      end
    end
  end
end
