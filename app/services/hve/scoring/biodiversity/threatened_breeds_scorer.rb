module Hve
  module Scoring
    module Biodiversity
      # Item 4.7 — Variétés / races menacées.
      # 1 pt par variété végétale menacée (cap 3) + 1 pt par race
      # animale menacée (cap 3). Saisie manuelle dans cette PR : la
      # liste de référence (Arrêté 29/04/2015, ~150 entrées) sera
      # vendorisée dans une PR ultérieure quand on aura le picker
      # auto-complete.
      #
      # Convention : deux items HveAuditItem distincts
      #   code='4.7.plant'   → nb de variétés végétales menacées
      #   code='4.7.animal'  → nb de races animales menacées
      # Ce scorer agrège les deux dans un item parent code='4.7'.
      class ThreatenedBreedsScorer
        POINTS_MAX = 6

        def initialize(audit:, sau: nil)
          @audit = audit
        end

        def call
          plant_count  = manual_count('4.7.plant')
          animal_count = manual_count('4.7.animal')
          plant_pts  = [plant_count, 3].min
          animal_pts = [animal_count, 3].min

          {
            code: '4.7',
            theme: 'biodiversity',
            value_raw: plant_count + animal_count,
            points: plant_pts + animal_pts,
            points_max: POINTS_MAX,
            auto_computed: false,
            evidence: {
              plant_count: plant_count,
              animal_count: animal_count,
              plant_points: plant_pts,
              animal_points: animal_pts
            }
          }
        end

        private

          def manual_count(code)
            @audit.items.find_by(code: code)&.value_manual.to_i
          end
      end
    end
  end
end
