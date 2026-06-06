module Hve
  module Scoring
    module Biodiversity
      # Item 4.5 — Nombre d'espèces animales.
      # 0-1 species → 0, 2 → 1, 3 → 2, ≥ 4 → 3.
      class AnimalSpeciesCountScorer
        POINTS_MAX = 3
        TABLE = [[4, 3], [3, 2], [2, 1]].freeze

        def initialize(audit:, sau: nil)
          @audit = audit
          @sau = sau || Shared::SauCalculator.new(audit)
        end

        def call
          n = @sau.animal_species_count
          pts = TABLE.find { |threshold, _p| n >= threshold }&.last || 0

          {
            code: '4.5',
            theme: 'biodiversity',
            value_raw: n,
            points: pts,
            points_max: POINTS_MAX,
            auto_computed: true,
            evidence: { animal_species_count: n }
          }
        end
      end
    end
  end
end
