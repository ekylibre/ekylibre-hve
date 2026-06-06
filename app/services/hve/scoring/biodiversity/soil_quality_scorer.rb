module Hve
  module Scoring
    module Biodiversity
      # Item 4.8 — Qualité biologique du sol.
      # 1 pt si test bêche OPVT OU analyse microbiologique réalisé
      # pendant la campagne. Saisie manuelle (booléen 0/1).
      class SoilQualityScorer
        POINTS_MAX = 1

        def initialize(audit:, sau: nil)
          @audit = audit
        end

        def call
          manual = @audit.items.find_by(code: '4.8')&.value_manual
          done = manual.to_i.positive?
          {
            code: '4.8',
            theme: 'biodiversity',
            value_raw: nil,
            value_manual: manual,
            points: done ? 1 : 0,
            points_max: POINTS_MAX,
            auto_computed: false,
            evidence: { soil_test_done: done }
          }
        end
      end
    end
  end
end
