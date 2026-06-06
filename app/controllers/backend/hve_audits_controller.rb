module Backend
  class HveAuditsController < Backend::BaseController
    manage_restfully identifier: 'id'

    # No `unroll` for now — the HveAudit model has no human-readable
    # identifier (name/number), and PR1 does not expose an autocomplete
    # picker for audits. Add it back later if a parent form needs to
    # reference an audit by id.

    list(order: { created_at: :desc }) do |t|
      t.action :show
      t.action :edit
      t.action :destroy
      t.column :campaign, url: true
      t.column :referentiel_version
      t.column :filiere
      t.column :status, label_method: 'status.tl'
      t.column :score_biodiversity
      t.column :score_phytosanitary
      t.column :score_fertilisation
      t.column :score_irrigation
      t.column :verdict, label_method: 'verdict ? verdict.tl : "-"'
    end

    def show
      return unless @hve_audit = find_and_check
      @themes = ::HveAudit::THEMES
      @items_by_theme = @hve_audit.items.group_by(&:theme)
    end

    def new
      @hve_audit = ::HveAudit.new(audit_defaults)
    end

    # Saisie + résumé du thème biodiversité.
    def biodiversity
      return unless @hve_audit = find_and_check
      @biodiversity_items = @hve_audit.biodiversity_items.includes(:audit).order(:iae_family, :iae_type)
      @iae_coefficients   = ::HveIaeCoefficient.order(:iae_family, :iae_type)
      @items_by_code      = @hve_audit.items.theme('biodiversity').index_by(&:code)
    end

    # Re-calcule le score biodiversité à partir des données courantes.
    def recompute_biodiversity
      return unless @hve_audit = find_and_check
      ::Hve::Scoring::BiodiversityScorer.call(audit: @hve_audit)
      redirect_to biodiversity_backend_hve_audit_path(@hve_audit),
                  notice: :scores_recomputed.tl(default: 'Scores recalculés.')
    end

    # Copie l'inventaire IAE de l'audit précédent (campagne antérieure
    # même tenant) vers l'audit courant. Pas de fusion : si l'audit
    # courant a déjà des items, on demande confirmation côté UI.
    def clone_from_previous
      return unless @hve_audit = find_and_check
      previous = previous_audit_for(@hve_audit)
      unless previous
        return redirect_to biodiversity_backend_hve_audit_path(@hve_audit),
                           alert: :no_previous_audit.tl(default: 'Aucun audit précédent trouvé.')
      end
      cloned = previous.biodiversity_items.map do |source|
        @hve_audit.biodiversity_items.create!(
          iae_family:        source.iae_family,
          iae_type:          source.iae_type,
          surface_or_length: source.surface_or_length,
          unit:              source.unit,
          location_notes:    source.location_notes
        )
      end
      redirect_to biodiversity_backend_hve_audit_path(@hve_audit),
                  notice: :clone_done.tl(default: 'Cloné %{count} items depuis l\'audit précédent.', count: cloned.size)
    end

    private

      def permitted_params
        params.require(:hve_audit).permit(
          :campaign_id, :referentiel_version, :filiere,
          :started_on, :closed_on, :status
        )
      end

      def audit_defaults
        current = current_user.current_campaign
        {
          campaign_id:         current&.id,
          referentiel_version: EkylibreHve::REFERENTIEL_VERSION,
          status:              'draft',
          started_on:          Date.today
        }
      end

      # Returns the most recent HveAudit closed before the current one
      # for the same tenant, or nil. Used by clone_from_previous.
      def previous_audit_for(audit)
        ::HveAudit.where('id <> ?', audit.id)
                  .joins(:campaign)
                  .where('campaigns.harvest_year < ?', audit.campaign&.harvest_year || 0)
                  .order('campaigns.harvest_year DESC')
                  .first
      end
  end
end
