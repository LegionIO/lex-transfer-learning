# frozen_string_literal: true

module Legion
  module Extensions
    module TransferLearning
      module Helpers
        class TransferEngine
          include Constants

          attr_reader :domains, :similarities, :transfer_history

          def initialize
            @domains          = {}
            @similarities     = {}
            @transfer_history = []
          end

          def set_similarity(domain_a:, domain_b:, similarity:)
            sim = similarity.clamp(0.0, 1.0).round(10)
            key = similarity_key(domain_a, domain_b)
            @similarities[key] = sim
            sim
          end

          def learn_domain(domain:, amount:)
            check_domain_limit!
            entry = get_or_create_domain(domain)
            entry.learn!(amount: amount.clamp(0.0, 1.0))
            entry.to_h
          end

          def attempt_transfer(from_domain:, to_domain:)
            source = @domains[from_domain]
            return { status: :source_not_found, from_domain: from_domain } unless source

            check_domain_limit!
            target     = get_or_create_domain(to_domain)
            sim        = similarity_between(from_domain, to_domain)
            type       = transfer_type(sim)
            distance   = transfer_distance(sim)
            effect     = apply_transfer_effect!(target, source, type)

            source.record_transfer!
            record_history!(from_domain, to_domain, sim, type, distance, effect)

            {
              status:      :ok,
              from_domain: from_domain,
              to_domain:   to_domain,
              similarity:  sim.round(10),
              type:        type,
              distance:    distance,
              effect:      effect,
              proficiency: target.proficiency.round(10)
            }
          end

          def transfer_effectiveness(from_domain:, to_domain:)
            source = @domains[from_domain]
            target = @domains[to_domain]
            sim    = similarity_between(from_domain, to_domain)
            type   = transfer_type(sim)

            {
              from_domain:          from_domain,
              to_domain:            to_domain,
              similarity:           sim.round(10),
              type:                 type,
              type_label:           TRANSFER_LABELS[type],
              distance:             transfer_distance(sim),
              distance_label:       DISTANCE_LABELS[transfer_distance(sim)],
              source_proficiency:   source&.proficiency&.round(10) || 0.0,
              target_proficiency:   target&.proficiency&.round(10) || 0.0
            }
          end

          def most_transferable(target_domain:, limit: 5)
            @domains
              .reject { |name, _| name == target_domain }
              .map do |name, entry|
                sim  = similarity_between(name, target_domain)
                type = transfer_type(sim)
                { domain: name, proficiency: entry.proficiency.round(10), similarity: sim.round(10), type: type }
              end
              .select { |r| r[:type] == :positive }
              .sort_by { |r| -r[:similarity] }
              .first(limit)
          end

          def interference_risks(target_domain:)
            @domains
              .reject { |name, _| name == target_domain }
              .filter_map do |name, entry|
                sim  = similarity_between(name, target_domain)
                type = transfer_type(sim)
                next unless type == :interference

                { domain: name, proficiency: entry.proficiency.round(10), similarity: sim.round(10) }
              end
              .sort_by { |r| -r[:similarity] }
          end

          def transfer_report
            total    = @transfer_history.size
            positive = @transfer_history.count { |h| h[:type] == :positive }
            negative = @transfer_history.count { |h| h[:type] == :negative }
            neutral  = @transfer_history.count { |h| h[:type] == :neutral }
            interf   = @transfer_history.count { |h| h[:type] == :interference }

            {
              total_transfers:       total,
              positive_transfers:    positive,
              negative_transfers:    negative,
              neutral_transfers:     neutral,
              interference_events:   interf,
              domain_count:          @domains.size,
              similarity_pairs:      @similarities.size
            }
          end

          def to_h
            {
              domains:          @domains.transform_values(&:to_h),
              similarities:     @similarities.dup,
              transfer_history: @transfer_history.dup,
              report:           transfer_report
            }
          end

          private

          def get_or_create_domain(name)
            @domains[name] ||= DomainKnowledge.new(domain: name)
          end

          def similarity_key(domain_a, domain_b)
            [domain_a, domain_b].sort.join(':')
          end

          def similarity_between(domain_a, domain_b)
            @similarities[similarity_key(domain_a, domain_b)] || 0.0
          end

          def transfer_type(similarity)
            if similarity >= POSITIVE_TRANSFER_THRESHOLD
              :positive
            elsif similarity >= NEGATIVE_TRANSFER_THRESHOLD
              :interference
            elsif similarity > 0.0
              :negative
            else
              :neutral
            end
          end

          def transfer_distance(similarity)
            if similarity >= POSITIVE_TRANSFER_THRESHOLD
              :near
            elsif similarity >= NEGATIVE_TRANSFER_THRESHOLD
              :moderate
            else
              :far
            end
          end

          def apply_transfer_effect!(target, source, type)
            scaled = (source.proficiency * TRANSFER_BOOST).round(10)
            case type
            when :positive
              target.apply_boost!(scaled)
              scaled
            when :interference
              penalty = (source.proficiency * INTERFERENCE_PENALTY).round(10)
              target.apply_penalty!(penalty)
              -penalty
            else
              0.0
            end
          end

          def record_history!(from_domain, to_domain, sim, type, distance, effect)
            @transfer_history << {
              from_domain: from_domain,
              to_domain:   to_domain,
              similarity:  sim.round(10),
              type:        type,
              distance:    distance,
              effect:      effect,
              at:          Time.now.utc
            }
          end

          def check_domain_limit!
            raise "domain limit of #{MAX_DOMAINS} reached" if @domains.size >= MAX_DOMAINS
          end
        end
      end
    end
  end
end
