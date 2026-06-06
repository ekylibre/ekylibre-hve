module Hve
  module Scoring
    module Biodiversity
      # Item 4.1 — Infrastructures Agro-Écologiques.
      # Gating criterion: if the audit has no biodiversity_items, the
      # whole biodiversity theme is non-eligible. Otherwise:
      #   0-7 pts on the IAE / arable surface ratio
      #   +2 pts bonus if ≥ 3 distinct IAE families are represented.
      class IaeScorer
        POINTS_MAX = 9

        # (ratio %, points) — strictly inclusive upper bound
        RATIO_TABLE = [
          [4,  1], [5, 2], [6, 3], [7, 4], [8, 5], [9, 6], [10, 7]
        ].freeze

        def initialize(audit:, sau: nil)
          @audit = audit
          @sau = sau || Shared::SauCalculator.new(audit)
        end

        def call
          # Fresh query, not the cached association, so the scorer stays
          # correct even when the caller mutated items in the same
          # request (e.g. destroyed then re-created).
          items = HveBiodiversityItem.where(hve_audit_id: @audit.id).to_a
          if items.empty?
            return base(value: 0, points: 0, evidence: { gate: 'iae_inventory_missing' })
          end

          total_iae = items.sum { |i| i.equivalent_iae_ha.to_d.to_f }
          arable = @sau.arable_ha
          ratio = arable.zero? ? 0 : (total_iae / arable * 100.0).round(2)
          base_pts = points_from_ratio(ratio)
          families = items.map(&:iae_family).uniq
          bonus = families.size >= 3 ? 2 : 0

          base(
            value: ratio,
            points: base_pts + bonus,
            evidence: {
              iae_total_ha: total_iae.round(4),
              arable_ha: arable.round(4),
              ratio_pct: ratio,
              base_points: base_pts,
              families_bonus: bonus,
              families_present: families
            }
          )
        end

        private

          def points_from_ratio(ratio)
            pts = 0
            RATIO_TABLE.each { |threshold, p| pts = p if ratio >= threshold }
            pts
          end

          def base(value:, points:, evidence:)
            {
              code: '4.1',
              theme: 'biodiversity',
              value_raw: value,
              points: points,
              points_max: POINTS_MAX,
              auto_computed: true,
              evidence: evidence
            }
          end
      end
    end
  end
end
