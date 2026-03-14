# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module TransferLearning
      module Helpers
        class DomainKnowledge
          attr_reader :id, :domain, :proficiency, :learn_count, :transfer_count

          PROFICIENCY_LABELS = [
            [0.0, 0.2,  'novice'],
            [0.2, 0.4,  'beginner'],
            [0.4, 0.6,  'intermediate'],
            [0.6, 0.8,  'advanced'],
            [0.8, 1.01, 'expert']
          ].freeze

          def initialize(domain:)
            @id             = SecureRandom.uuid
            @domain         = domain
            @proficiency    = 0.0
            @learn_count    = 0
            @transfer_count = 0
          end

          def learn!(amount:)
            @proficiency = (@proficiency + amount).clamp(0.0, 1.0).round(10)
            @learn_count += 1
            self
          end

          def record_transfer!
            @transfer_count += 1
            self
          end

          def apply_boost!(amount)
            @proficiency = (@proficiency + amount).clamp(0.0, 1.0).round(10)
            self
          end

          def apply_penalty!(amount)
            @proficiency = (@proficiency - amount).clamp(0.0, 1.0).round(10)
            self
          end

          def proficiency_label
            PROFICIENCY_LABELS.each do |low, high, label|
              return label if @proficiency >= low && @proficiency < high
            end
            'novice'
          end

          def to_h
            {
              id:                @id,
              domain:            @domain,
              proficiency:       @proficiency.round(10),
              proficiency_label: proficiency_label,
              learn_count:       @learn_count,
              transfer_count:    @transfer_count
            }
          end
        end
      end
    end
  end
end
