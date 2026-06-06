module Hve
  module Scoring
    module Biodiversity
      # Item 4.2 — Taille des parcelles.
      # Score on % SAU in parcels < 6 ha OR permanent grassland.
      class ParcelSizeScorer
        POINTS_MAX = 5
        TABLE = [[40, 1], [50, 2], [60, 3], [70, 4], [80, 5]].freeze

        def initialize(audit:, sau: nil)
          @audit = audit
          @sau = sau || Shared::SauCalculator.new(audit)
        end

        def call
          share = @sau.small_or_grassland_share
          pts = 0
          TABLE.each { |threshold, p| pts = p if share >= threshold }

          {
            code: '4.2',
            theme: 'biodiversity',
            value_raw: share,
            points: pts,
            points_max: POINTS_MAX,
            auto_computed: true,
            evidence: {
              small_or_grassland_share_pct: share,
              total_sau_ha: @sau.total_sau_ha.round(4),
              small_parcels_ha: @sau.small_parcels_ha.round(4),
              permanent_grassland_ha: @sau.permanent_grassland_ha.round(4)
            }
          }
        end
      end
    end
  end
end
