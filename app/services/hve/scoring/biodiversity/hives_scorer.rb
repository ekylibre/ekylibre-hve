module Hve
  module Scoring
    module Biodiversity
      # Item 4.6 — Présence de ruches.
      # 1 pt si ≥ 3 ruches sédentaires. Pas de modèle Ekylibre pour les
      # ruches dans cette PR — la valeur est saisie manuellement par
      # l'utilisateur dans HveAuditItem(code='4.6').value_manual.
      class HivesScorer
        POINTS_MAX = 1

        def initialize(audit:, sau: nil)
          @audit = audit
        end

        def call
          manual = manual_value
          count = manual.to_i
          {
            code: '4.6',
            theme: 'biodiversity',
            value_raw: nil,
            value_manual: manual,
            points: count >= 3 ? 1 : 0,
            points_max: POINTS_MAX,
            auto_computed: false,
            evidence: { hive_count: count }
          }
        end

        private

          def manual_value
            @audit.items.find_by(code: '4.6')&.value_manual
          end
      end
    end
  end
end
