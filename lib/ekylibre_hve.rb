require 'ekylibre_hve/version'
require 'ekylibre_hve/engine'
require 'ekylibre_hve/ext_navigation'

module EkylibreHve
  REFERENTIEL_VERSION = 'V4.4'.freeze

  CMR_SNAPSHOT_YEAR = 2025

  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  # Threshold (in points) for each thematic indicator. Certification is
  # granted when every score reaches this value AND no CMR1 product was
  # used without derogation.
  CERTIFICATION_THRESHOLD = 10

  # Maximum theoretical points per indicator (from grille V4.4).
  MAX_POINTS = {
    biodiversity:  36,
    phytosanitary: 63,
    fertilisation: 53,
    irrigation:    34
  }.freeze
end
