module Hve
  module Scoring
    module Shared
      # Aggregates SAU (Surface Agricole Utile) and related ratios
      # consumed by every biodiversity scorer (and reused by phyto /
      # fertilisation / irrigation scorers in later PRs).
      #
      # All surfaces are returned in hectares. Lookups are memoized
      # per instance — callers should keep a single instance per audit
      # to avoid repeated SQL queries.
      class SauCalculator
        # Cultivation variety codes (Onoma) considered as permanent
        # grassland for HVE scoring. These are *string* matches against
        # `Activity#cultivation_variety`. Extend in a YAML config later
        # if the list grows.
        PERMANENT_GRASSLAND_VARIETIES = %w[grass pasture meadow].freeze

        attr_reader :audit, :campaign

        def initialize(audit)
          @audit = audit
          @campaign = audit.campaign
        end

        def productions
          @productions ||= ActivityProduction
                             .of_campaign(@campaign)
                             .includes(:activity)
                             .to_a
        end

        def total_sau_ha
          @total_sau_ha ||= ha_sum(productions)
        end

        def permanent_grassland_ha
          @permanent_grassland_ha ||= ha_sum(grassland_productions)
        end

        def arable_ha
          [total_sau_ha - permanent_grassland_ha, 0].max
        end

        def small_parcels_ha
          @small_parcels_ha ||= ha_sum(productions.select { |p| ha_of(p) > 0 && ha_of(p) < 6 })
        end

        # % SAU in parcels < 6 ha OR permanent grassland (item 4.2).
        def small_or_grassland_share
          return 0.0 if total_sau_ha.zero?
          covered = ha_sum(productions.select { |p| ha_of(p) < 6 } + grassland_productions)
          # Dedup: a permanent grassland < 6 ha counted twice — subtract overlap.
          overlap = ha_sum(grassland_productions.select { |p| ha_of(p) < 6 })
          ((covered - overlap) / total_sau_ha * 100).round(2)
        end

        # % of arable SAU occupied by the dominant crop (item 4.3).
        def main_crop_share
          return 0.0 if arable_ha.zero?
          by_variety = productions.reject { |p| grassland?(p) }
                                  .group_by { |p| cultivation_variety_of(p) }
          return 0.0 if by_variety.empty?
          dominant_ha = by_variety.values.map { |list| ha_sum(list) }.max || 0
          (dominant_ha / arable_ha * 100).round(2)
        end

        # Distinct count of cultivation varieties on the campaign,
        # excluding permanent grassland (item 4.4).
        def plant_species_count
          productions.reject { |p| grassland?(p) }
                     .map { |p| cultivation_variety_of(p) }
                     .compact
                     .uniq
                     .size
        end

        # Distinct animal varieties alive on the campaign (item 4.5).
        # We use the variety code (Onoma) as proxy for species — a finer
        # mapping race→species is deferred to a later PR.
        def animal_species_count
          window = campaign_window
          return 0 unless window
          Animal.where('born_at <= ?', window.last)
                .where('dead_at IS NULL OR dead_at >= ?', window.first)
                .distinct.pluck(:variety)
                .compact
                .uniq
                .size
        end

        # Convenience: list of productions whose support has no geometry —
        # surfaced in the scorer evidence so the user can fix them.
        def productions_without_geometry
          productions.reject { |p| ha_of(p).positive? }
        end

        private

          def grassland_productions
            @grassland_productions ||= productions.select { |p| grassland?(p) }
          end

          def grassland?(production)
            return false unless production.activity
            variety = cultivation_variety_of(production)
            PERMANENT_GRASSLAND_VARIETIES.include?(variety.to_s)
          end

          def cultivation_variety_of(production)
            production.activity&.cultivation_variety.to_s
          end

          def ha_of(production)
            measure = production.support_shape_area
            return 0.0 if measure.nil?
            measure.convert(:hectare).to_d.to_f
          rescue StandardError
            0.0
          end

          def ha_sum(list)
            list.sum { |p| ha_of(p) }.to_d.to_f
          end

          def campaign_window
            return nil unless @campaign
            year = @campaign.harvest_year
            return nil unless year
            Date.new(year, 1, 1)..Date.new(year, 12, 31)
          end
      end
    end
  end
end
