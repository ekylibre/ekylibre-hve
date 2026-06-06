module Hve
  module Scoring
    # Orchestrator: runs all 8 biodiversity sub-scorers, upserts the
    # results in HveAuditItem, and updates the cached score on the
    # audit. Idempotent: re-running on unchanged data yields the same
    # rows and the same scores. Manual overrides (value_manual) are
    # preserved.
    class BiodiversityScorer
      SCORERS = [
        Biodiversity::IaeScorer,                # 4.1 — gating
        Biodiversity::ParcelSizeScorer,         # 4.2
        Biodiversity::MainCropWeightScorer,     # 4.3
        Biodiversity::PlantSpeciesCountScorer,  # 4.4
        Biodiversity::AnimalSpeciesCountScorer, # 4.5
        Biodiversity::HivesScorer,              # 4.6
        Biodiversity::ThreatenedBreedsScorer,   # 4.7
        Biodiversity::SoilQualityScorer         # 4.8
      ].freeze

      def self.call(audit:)
        new(audit: audit).call
      end

      def initialize(audit:)
        @audit = audit
        @sau = Shared::SauCalculator.new(audit)
      end

      def call
        results = SCORERS.map { |klass| klass.new(audit: @audit, sau: @sau).call }
        ActiveRecord::Base.transaction do
          results.each { |r| upsert_item(r) }
          total = results.sum { |r| r[:points] }
          @audit.update!(
            score_biodiversity: total,
            metadata: @audit.metadata.merge(
              'biodiversity_gate' => iae_gate_value(results.first)
            )
          )
        end
        @audit.reload
        {
          score: @audit.score_biodiversity,
          gate_open: @audit.metadata['biodiversity_gate'],
          items: results
        }
      end

      private

        def upsert_item(result)
          item = @audit.items.find_or_initialize_by(code: result[:code])
          item.theme         = result[:theme]
          item.value_raw     = result[:value_raw]
          # Don't overwrite a user's manual entry on auto rerun.
          item.value_manual  = result[:value_manual] if result.key?(:value_manual) && item.value_manual.blank?
          item.points        = result[:points]
          item.points_max    = result[:points_max]
          item.auto_computed = result[:auto_computed]
          item.evidence      = result[:evidence]
          item.save!
        end

        def iae_gate_value(iae_result)
          (iae_result[:evidence] || {})[:gate].to_s == 'iae_inventory_missing' ? 'closed' : 'open'
        end
    end
  end
end
