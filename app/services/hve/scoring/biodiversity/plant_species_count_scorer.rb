module Hve
  module Scoring
    module Biodiversity
      # Item 4.4 — Nombre d'espèces végétales cultivées.
      # Score bracketed by item 4.3 main_crop_share:
      #   case 1 (≥ 60 %): 4 species → 0, +1 per species, max 5
      #   case 2 (< 60 %): 4 species → 0, +1 per species, max 6
      class PlantSpeciesCountScorer
        POINTS_MAX = 6
        BASELINE = 4 # 4 species = 0 pts, then +1 per extra

        def initialize(audit:, sau: nil)
          @audit = audit
          @sau = sau || Shared::SauCalculator.new(audit)
        end

        def call
          n = @sau.plant_species_count
          cap = @sau.main_crop_share >= 60 ? 5 : POINTS_MAX
          pts = [[n - BASELINE, 0].max, cap].min

          {
            code: '4.4',
            theme: 'biodiversity',
            value_raw: n,
            points: pts,
            points_max: POINTS_MAX,
            auto_computed: true,
            evidence: {
              plant_species_count: n,
              cap_applied: cap,
              main_crop_share_pct: @sau.main_crop_share
            }
          }
        end
      end
    end
  end
end
