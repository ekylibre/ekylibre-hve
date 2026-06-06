module Backend
  class HveBiodiversityItemsController < Backend::BaseController
    before_action :find_audit

    def new
      @item = @audit.biodiversity_items.new
    end

    def create
      @item = @audit.biodiversity_items.new(item_params)
      if @item.save
        redirect_to biodiversity_backend_hve_audit_path(@audit),
                    notice: :record_x_created.tl(record: @item.iae_type)
      else
        render :new
      end
    end

    def edit
      @item = @audit.biodiversity_items.find(params[:id])
    end

    def update
      @item = @audit.biodiversity_items.find(params[:id])
      if @item.update(item_params)
        redirect_to biodiversity_backend_hve_audit_path(@audit),
                    notice: :record_x_updated.tl(record: @item.iae_type)
      else
        render :edit
      end
    end

    def destroy
      item = @audit.biodiversity_items.find(params[:id])
      item.destroy
      redirect_to biodiversity_backend_hve_audit_path(@audit),
                  notice: :record_destroyed.tl(default: 'Élément supprimé.')
    end

    private

      def find_audit
        @audit = ::HveAudit.find(params[:hve_audit_id])
      end

      def item_params
        params.require(:hve_biodiversity_item).permit(
          :iae_family, :iae_type, :surface_or_length, :unit, :coefficient, :location_notes
        )
      end
  end
end
