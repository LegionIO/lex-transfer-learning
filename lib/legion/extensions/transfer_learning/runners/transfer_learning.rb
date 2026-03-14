# frozen_string_literal: true

module Legion
  module Extensions
    module TransferLearning
      module Runners
        module TransferLearning
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def learn_domain(domain:, amount:, **)
            result = transfer_engine.learn_domain(domain: domain, amount: amount)
            Legion::Logging.info "[transfer_learning] learn: domain=#{domain} amount=#{amount} proficiency=#{result[:proficiency]}"
            result
          end

          def attempt_transfer(from_domain:, to_domain:, **)
            result = transfer_engine.attempt_transfer(from_domain: from_domain, to_domain: to_domain)
            Legion::Logging.info "[transfer_learning] transfer: from=#{from_domain} to=#{to_domain} type=#{result[:type]} effect=#{result[:effect]}"
            result
          end

          def set_similarity(domain_a:, domain_b:, similarity:, **)
            sim = transfer_engine.set_similarity(domain_a: domain_a, domain_b: domain_b, similarity: similarity)
            Legion::Logging.debug "[transfer_learning] similarity set: #{domain_a}<->#{domain_b} similarity=#{sim}"
            { domain_a: domain_a, domain_b: domain_b, similarity: sim }
          end

          def transfer_effectiveness(from_domain:, to_domain:, **)
            result = transfer_engine.transfer_effectiveness(from_domain: from_domain, to_domain: to_domain)
            Legion::Logging.debug "[transfer_learning] effectiveness: from=#{from_domain} to=#{to_domain} type=#{result[:type]}"
            result
          end

          def most_transferable(target_domain:, limit: 5, **)
            candidates = transfer_engine.most_transferable(target_domain: target_domain, limit: limit)
            Legion::Logging.debug "[transfer_learning] most_transferable: target=#{target_domain} found=#{candidates.size}"
            { target_domain: target_domain, candidates: candidates, count: candidates.size }
          end

          def interference_risks(target_domain:, **)
            risks = transfer_engine.interference_risks(target_domain: target_domain)
            Legion::Logging.debug "[transfer_learning] interference_risks: target=#{target_domain} risks=#{risks.size}"
            { target_domain: target_domain, risks: risks, count: risks.size }
          end

          def transfer_report(**)
            report = transfer_engine.transfer_report
            Legion::Logging.debug "[transfer_learning] report: domains=#{report[:domain_count]} transfers=#{report[:total_transfers]}"
            report
          end

          def get_domain(domain:, **)
            entry = transfer_engine.domains[domain]
            if entry
              Legion::Logging.debug "[transfer_learning] get_domain: domain=#{domain} proficiency=#{entry.proficiency}"
              { found: true, domain: entry.to_h }
            else
              Legion::Logging.debug "[transfer_learning] get_domain: domain=#{domain} not found"
              { found: false, domain: domain }
            end
          end

          private

          def transfer_engine
            @transfer_engine ||= Helpers::TransferEngine.new
          end
        end
      end
    end
  end
end
