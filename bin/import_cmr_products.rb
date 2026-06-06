#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Imports the official CMR products list from the ministry XLSX into
# `db/seeds/hve_cmr_products_<year>.csv`.
#
# Usage:
#   bundle exec ruby bin/import_cmr_products.rb \
#       --xlsx "/path/to/HVE_Liste des PPP classés CMR_au_21.10.25.vf_.xlsx" \
#       --sheet "Snapshot 2025" \
#       --year  2025
#
# Requires the `roo` gem on the host (NOT bundled with this plugin).
# Output is committed in db/seeds/ so the production app doesn't need
# `roo` at runtime — only the CSV is consumed by hve:reference:load.

require 'optparse'
require 'csv'

begin
  require 'roo'
rescue LoadError
  abort "This script requires the 'roo' gem. Install it with: gem install roo"
end

options = { sheet: 'Snapshot 2025', year: 2025 }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby #{$PROGRAM_NAME} --xlsx PATH [options]"
  opts.on('--xlsx PATH',   'Path to the ministry XLSX file')              { |v| options[:xlsx]  = v }
  opts.on('--sheet NAME',  'Sheet name (default: Snapshot 2025)')         { |v| options[:sheet] = v }
  opts.on('--year YEAR',   Integer, 'Snapshot year (default: 2025)')      { |v| options[:year]  = v }
  opts.on('--out PATH',    'Output CSV path (default: db/seeds/...)')     { |v| options[:out]   = v }
end.parse!

abort 'Missing --xlsx' unless options[:xlsx]
options[:out] ||= File.expand_path("../db/seeds/hve_cmr_products_#{options[:year]}.csv", __dir__)

book = Roo::Excelx.new(options[:xlsx])
sheet = book.sheet(options[:sheet])
header_row = 8 # column titles live on row 8 in the published file

rows = []
((header_row + 1)..sheet.last_row).each do |i|
  row = sheet.row(i)
  next if row.compact.empty?
  rows << {
    amm_code:                row[2]&.to_s&.strip,
    product_name:            row[0]&.to_s&.strip,
    cmr_class:               row[6]&.to_s&.strip,
    status:                  row[8]&.to_s&.strip,
    first_authorisation_on:  row[9],
    withdrawal_on:           row[10],
    type_label:              row[3]&.to_s&.strip,
    active_substances:       row[4]&.to_s&.strip,
    functions:               row[5]&.to_s&.strip
  }
end

CSV.open(options[:out], 'w') do |csv|
  csv << %i[amm_code product_name cmr_class status first_authorisation_on withdrawal_on type_label active_substances functions]
  rows.each { |r| csv << r.values }
end

puts "Wrote #{rows.size} rows to #{options[:out]}"
