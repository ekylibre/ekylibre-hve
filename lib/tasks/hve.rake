require 'csv'
require 'yaml'

namespace :hve do
  namespace :reference do
    desc 'Load HVE reference data (CMR products, nitrogen export coefficients, IFT scoring tables) into the TENANT=name tenant.'
    task load: :environment do
      tenant = ENV['TENANT']
      raise 'Set TENANT=<name>' if tenant.blank?

      Ekylibre::Tenant.switch(tenant) do
        load_cmr_products
        load_nitrogen_exports
        load_scoring_tables
        load_iae_coefficients
        puts "[HVE] reference data loaded into tenant #{tenant}"
      end
    end

    desc 'Print row counts for each HVE reference table in the TENANT=name tenant.'
    task status: :environment do
      tenant = ENV['TENANT']
      raise 'Set TENANT=<name>' if tenant.blank?

      Ekylibre::Tenant.switch(tenant) do
        puts "[HVE] tenant: #{tenant}"
        puts "  hve_cmr_products:                  #{HveCmrProduct.count}"
        puts "  hve_nitrogen_export_coefficients:  #{HveNitrogenExportCoefficient.count}"
        puts "  hve_scoring_tables:                #{HveScoringTable.count}"
        puts "  hve_iae_coefficients:              #{HveIaeCoefficient.count}"
      end
    end
  end

  def load_cmr_products
    seeds_dir = EkylibreHve.root.join('db', 'seeds')
    files = Dir[seeds_dir.join('hve_cmr_products_*.csv')]
    return if files.empty?

    inserted = 0
    files.each do |path|
      year = File.basename(path)[/\d{4}/].to_i
      raise "Cannot infer snapshot year from #{path}" if year.zero?

      HveCmrProduct.transaction do
        HveCmrProduct.where(snapshot_year: year).delete_all
        CSV.foreach(path, headers: true, skip_blanks: true) do |row|
          next if row.to_s.start_with?('#')
          next if row['amm_code'].blank?
          HveCmrProduct.create!(
            amm_code:               row['amm_code'].to_s.strip,
            product_name:           row['product_name'],
            cmr_class:              row['cmr_class'],
            status:                 row['status'],
            first_authorisation_on: parse_date(row['first_authorisation_on']),
            withdrawal_on:          parse_date(row['withdrawal_on']),
            snapshot_year:          year,
            type_label:             row['type_label'],
            active_substances:      row['active_substances'],
            functions:              row['functions']
          )
          inserted += 1
        end
      end
    end
    puts "[HVE] loaded #{inserted} CMR product rows"
  end

  def load_nitrogen_exports
    path = EkylibreHve.root.join('db', 'seeds', 'hve_nitrogen_exports.csv')
    return unless File.exist?(path)

    inserted = 0
    HveNitrogenExportCoefficient.transaction do
      HveNitrogenExportCoefficient.delete_all
      CSV.foreach(path, headers: true, skip_blanks: true) do |row|
        next if row.to_s.start_with?('#')
        next if row['crop_reference'].blank?
        HveNitrogenExportCoefficient.create!(
          crop_reference: row['crop_reference'],
          organ:          row['organ'],
          ms_pct:         row['ms_pct'],
          n_kg_per_t:     row['n_kg_per_t'],
          unit:           row['unit'] || 'fresh_matter',
          source:         row['source']
        )
        inserted += 1
      end
    end
    puts "[HVE] loaded #{inserted} nitrogen export coefficients"
  end

  def load_scoring_tables
    path = EkylibreHve.root.join('db', 'seeds', 'hve_scoring_tables.yml')
    return unless File.exist?(path)

    rows = YAML.load_file(path)
    return unless rows.is_a?(Array)

    HveScoringTable.transaction do
      HveScoringTable.delete_all
      rows.each do |attrs|
        HveScoringTable.create!(attrs.merge('referentiel_version' => EkylibreHve::REFERENTIEL_VERSION))
      end
    end
    puts "[HVE] loaded #{rows.size} IFT scoring rows"
  end

  def load_iae_coefficients
    path = EkylibreHve.root.join('db', 'seeds', 'hve_iae_coefficients.yml')
    return unless File.exist?(path)

    rows = YAML.load_file(path)
    return unless rows.is_a?(Array)

    HveIaeCoefficient.transaction do
      HveIaeCoefficient.delete_all
      rows.each { |attrs| HveIaeCoefficient.create!(attrs) }
    end
    puts "[HVE] loaded #{rows.size} IAE coefficient rows"
  end

  def parse_date(str)
    return nil if str.blank?
    Date.parse(str.to_s)
  rescue ArgumentError
    nil
  end
end
