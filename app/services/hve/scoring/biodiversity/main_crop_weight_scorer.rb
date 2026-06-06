module Hve
  module Scoring
    module Biodiversity
      # Item 4.3 — Poids de la culture principale.
      # Score INVERSELY on the % of arable SAU occupied by the dominant
      # crop: the more diversified the rotation, the higher the score.
      class MainCropWeightScorer
        POINTS_MAX = 5
        # Descending pivots: ≥ value → points
        TABLE = [[60, 0], [50, 1], [40, 2], [30, 3], [20, 4], [0, 5]].freeze

        def initialize(audit:, sau: nil)
          @audit = audit
          @sau = sau || Shared::SauCalculator.new(audit)
        end

        def call
          share = @sau.main_crop_share
          pts = TABLE.find { |threshold, _p| share >= threshold }&.last || 0

          {
            code: '4.3',
            theme: 'biodiversity',
            value_raw: share,
            points: pts,
            points_max: POINTS_MAX,
            auto_computed: true,
            evidence: {
              main_crop_share_pct: share,
              arable_ha: @sau.arable_ha.round(4)
            }
          }
        end
      end
    end
  end
end
