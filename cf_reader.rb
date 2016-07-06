#! /usr/bin/env ruby

require 'yaml'

def log(s)
  puts s if $verbose
end

def read_marker(f)
  marker = f.read(2)
  raise 'Not a channel file' unless marker[0] == 'C' and marker[1] == 'F'
end

def read_bool(f)
  f.read(1).unpack('C')[0] != 0
end

def read_byte(f)
  f.read(1).unpack('C')[0]
end

def read_short(f)
  f.read(2).unpack('S')[0]
end

def read_long(f)
  f.read(4).unpack('L')[0]
end

def read_float(f)
  f.read(4).unpack('F')[0]
end

def read_string(f)
  f.read(read_long(f))
end

def read_header(f)
  {
    :generating_station => read_byte(f),
    :unit_number => read_byte(f),
    :year => read_byte(f),
    :month => read_byte(f),
    :day => read_byte(f),
    :channel_abscissa => read_byte(f),
    :channel_ordinate => read_byte(f),
    :channel_end => read_byte(f),
    :reactor_face => read_byte(f),
    :inspection_head => read_string(f),
    :operator_name => read_string(f),
    :date => read_string(f),
    :time => read_string(f)
  }
end

def read_bytes(f, n)
  bytes = []
  n.times do
    bytes << read_byte(f)
  end
  bytes
end

def read_calibration_entry(f)
  log "Reading calibration entry..."
  {
    :state => read_long(f),
    :filename => read_string(f),
    :levels => read_bytes(f, 14),
    :raw_levels => read_bytes(f, 14),
    :hardware_gains => read_bytes(f, 14),
    :software_gains => read_bytes(f, 14),
    :description => read_string(f)
  }
end

def read_calibration_entries(f)
  count = read_long(f)
  log "Reading #{count} calibration entries..."
  entries = []
  count.times do
    entries << read_calibration_entry(f)
  end
  entries
end

def read_calibration(f)
  log "Reading calibration record..."
  {
    :state => read_long(f),
    :start_time => read_long(f),
    :inspection_head => read_string(f),
    :entries => read_calibration_entries(f),
    :pv_calibration_filename => read_string(f)
  }
end

def read_calibrations(f)
  count = read_long(f)
  log "Reading #{count} calibration records..."
  calibrations = []
  count.times do
    calibrations << read_calibration(f)
  end
  calibrations
end

def read_overridable_location(f)
  log "Reading overridable location..."
  {
    :detected => read_bool(f),
    :detected_value => read_float(f),
    :overridden => read_bool(f),
    :manual_value => read_float(f)
  }
end

def read_rolls(f)
  log "Reading rolls..."
  rolls = []
  3.times do
    rolls << read_overridable_location(f)
  end
  rolls
end

def read_rolled_joint(f)
  log "Reading rolled joint..."
  return nil unless read_bool(f)
  {
    :axial_start => read_overridable_location(f),
    :axial_end => read_overridable_location(f),
    :burnish_mark => read_overridable_location(f),
    :rolls => read_rolls(f),
    :end_of_pressure_tube => read_overridable_location(f),
    :taper => read_overridable_location(f),
    :end => read_long(f)
  }
end

def read_rolled_joints(f)
  log "Reading rolled joints..."
  {
    :inlet => read_rolled_joint(f),
    :outlet => read_rolled_joint(f)
  }
end

def read_analysis_element(f)
  log "Reading analysis element common fields..."
  {
    :id => read_long(f),
    :axial_start => read_float(f),
    :axial_end => read_float(f),
    :rotary_start => read_float(f),
    :rotary_end => read_float(f),
    :channel => read_long(f),
    :description => read_string(f),
    :calibration_id => read_long(f),
    :enabled => read_bool(f),
    :redundant_master => read_long(f),
    :disable_reason => read_string(f),
    :accepted => read_bool(f),
    :custom => read_bool(f)
  }
end

def read_rescan_element(f)
  log "Reading rescan element..."
  element = read_analysis_element(f)
  element[ :type ] = read_long(f)
  element[ :resolved ] = read_bool(f)
  element
end

def read_rescan_elements(f)
  count = read_long(f)
  log "Reading #{count} rescan elements..."
  elements = []
  count.times do
    elements << read_rescan_element(f)
  end
  elements
end

def read_bscan_element(f)
  log "Reading bscan element..."
  element = read_analysis_element(f)
  element[ :mandatory ] = read_bool(f)
  element
end

def read_bscan_elements(f)
  count = read_long(f)
  log "Reading #{count} bscan elements..."
  elements = []
  count.times do
    elements << read_bscan_element(f)
  end
  elements
end

def read_reportable_element(f)
  log "Reading reportable element..."
  read_analysis_element(f)
end

def read_reportable_elements(f)
  count = read_long(f)
  log "Reading #{count} reportable elements..."
  elements = []
  count.times do
    elements << read_reportable_element(f)
  end
  elements
end

def read_element_ids(f)
  count = read_long(f)
  log "Reading #{count} ids..."
  ids = []
  count.times do
    ids << read_long(f)
  end
  ids
end

def read_extended_indication_marker(f)
  log "Reading extended indication marker..."
  f.read(2)
end

def read_depth_profile_element(f)
  log "Reading depth profile element..."
  {
    :axial => read_float(f),
    :rotary => read_float(f),
    :max_depth => read_float(f)
  }
end

def read_depth_profile_elements(f)
  count = read_long(f)
  log "Reading #{count} depth profile elements..."
  elements = []
  count.times do
    elements << read_depth_profile_element(f)
  end
  elements
end

def read_dfp_marker(f)
  log "Reading dfp marker..."
  f.read(3)
end

def read_dfp_wall_thickness_measurement(f)
  log "Reading dfp wall thickness measurement..."
  {
    :axial => read_float(f),
    :rotary => read_float(f),
    :wall_thickness_in_us => read_float(f),
    :us_to_mm_conversion => read_float(f),
    :us_to_mm_conversion_description => read_string(f)
  }
end

def read_dfp_wall_thickness_measurements(f)
  count = read_long(f)
  log "Reading #{count} dfp wall thickness measurements..."
  measurements = []
  count.times do
    measurements << read_dfp_wall_thickness_measurement(f)
  end
  measurements
end

def read_dfp(f)
  marker = read_dfp_marker(f)
  if marker[0] == 'D' and marker[1] == 'F' and marker[2] = 'P'
    {
      :dfp_wall_thickness_measurements => read_dfp_wall_thickness_measurements(f)
    }
  else
    # ... you would think we'd roll the file pointer back...
    # ... could be the source of the channel file corruption bugs...
    nil
  end
end

def read_indication_extended(f)
  marker = read_extended_indication_marker(f)
  if marker[0] == 'E' and marker[1] == 'I'
    log "Reading extended indication fields..."
    {
      :maximum_cw_amplitude => read_float(f),
      :maximum_ccw_amplitude => read_float(f),
      :maximum_fwd_amplitude => read_float(f),
      :maximum_back_amplitude => read_float(f),
      :scan_sensitivity_relative_to_notch => read_float(f),
      :maximum_amplitude_screen_height => read_byte(f),
      :maximum_cw_amplitude_screen_height => read_byte(f),
      :maximum_ccw_amplitude_screen_height => read_byte(f),
      :maximum_fwd_amplitude_screen_height => read_byte(f),
      :maximum_back_amplitude_screen_height => read_byte(f),
      :nb_second_backwall_background_level_screen_height => read_byte(f),
      :nb_flaw_max_drop_screen_height => read_byte(f),
      :flaw_6db_drop_level_screen_height => read_byte(f),
      :nb_flaw_max_drop_relative_to_background_level => read_float(f),
      :flaw_6db_drop_relative_to_background_level => read_float(f),
      :max_cpc_depth_in_us => read_float(f),
      :max_cpc_depth_us_to_mm_conversion => read_float(f),
      :max_cpc_depth_axial_location => read_float(f),
      :max_cpc_depth_rotary_location => read_float(f),
      :max_apc_depth_in_us => read_float(f),
      :max_apc_depth_us_to_mm_conversion => read_float(f),
      :max_apc_depth_axial_location => read_float(f),
      :max_apc_depth_rotary_location => read_float(f),
      :sizing_automatic => read_bool(f),
      :maximum_amplitude_automatic => read_bool(f),
      :maximum_depth_automatic => read_bool(f),
      :wall_thickness_automatic => read_bool(f),
      :depth_profile_automatic => read_bool(f),
      :cpc_depth_profile_automatic => read_bool(f),
      :apc_depth_profile_automatic => read_bool(f),
      :depth_profile_elements => read_depth_profile_elements(f),
      :cpc_depth_profile_elements => read_depth_profile_elements(f),
      :apc_depth_profile_elements => read_depth_profile_elements(f),
      :indication_label => read_string(f),
      :analyst_id => read_long(f),
      :manually_created => read_bool(f),
      :depth_was_from_20mhz => read_bool(f),
      :dfp => read_dfp(f)
    }
  else
    log "Rewinding because no extended indication marker found..."
    f.seek(-2, IO::SEEK_CUR)
    nil
  end
end

def read_indication(f)
  log "Reading indication..."
  {
    :id => read_long(f),
    :axial_centre => read_float(f),
    :rotary_centre => read_float(f),
    :width => read_float(f),
    :length => read_float(f),
    :angle => read_float(f),
    :tube_radius => read_float(f),
    :maximum_amplitude => read_float(f),
    :maximum_depth_in_us => read_float(f),
    :maximum_depth_us_to_mm_conversion => read_float(f),
    :maximum_depth_axial_location => read_float(f),
    :maximum_depth_rotary_location => read_float(f),
    :wall_thickness_in_us => read_float(f),
    :wall_thickness_us_to_mm_conversion => read_float(f),
    :maximum_depth_us_to_mm_conversion_description => read_string(f),
    :wall_thickness_us_to_mm_conversion_description => read_string(f),
    :comments => read_string(f),
    :type => read_long(f),
    :location => read_long(f),
    :reportable_element_ids => read_element_ids(f),
    :bscan_element_ids => read_element_ids(f),
    :extended => read_indication_extended(f)
  }
end

def read_indications(f)
  count = read_long(f)
  log "Reading #{count} indications..."
  elements = []
  count.times do
    elements << read_indication(f)
  end
  elements
end

def read_rescan_record(f)
  log "Reading rescan record..."
  {
    :id => read_long(f),
    :axial_start => read_float(f),
    :axial_end => read_float(f),
    :flags => read_long(f),
    :completed => read_bool(f),
    :calibration_id => read_long(f),
    :elements => read_element_ids(f)
  }
end

def read_rescan_records(f)
  count = read_long(f)
  log "Reading #{count} rescan records..."
  records = []
  count.times do
    records << read_rescan_record(f)
  end
  records
end

def read_bscan_record(f)
  log "Reading bscan record..."
  {
    :id => read_long(f),
    :axial_start => read_float(f),
    :axial_end => read_float(f),
    :rotary_start => read_float(f),
    :rotary_end => read_float(f),
    :completed => read_bool(f),
    :mandatory_region => read_bool(f),
    :calibration_id => read_long(f),
    :elements => read_element_ids(f)
  }
end

def read_bscan_records(f)
  count = read_long(f)
  log "Reading #{count} bscan records..."
  records = []
  count.times do
    records << read_bscan_record(f)
  end
  records
end

def read_scan_file_record(f)
  log "Reading scan file record..."
  {
    :filename => read_string(f),
    :rescan_record_ids => read_element_ids(f),
    :bscan_record_ids => read_element_ids(f),
    :reportable_element_ids => read_element_ids(f)
  }
end

def read_scan_file_records(f)
  count = read_long(f)
  log "Reading #{count} scan file records..."
  records = []
  count.times do
    records << read_scan_file_record(f)
  end
  records
end

def read_channel_file(filename)
  channel_file = {}
  File.open(filename, 'rb') do |f|
    read_marker(f)
    channel_file[ :header ] = read_header(f)
    channel_file[ :calibrations ] = read_calibrations(f)
    channel_file[ :rolled_joints ] = read_rolled_joints(f)
    channel_file[ :rescan_elements ] = read_rescan_elements(f)
    channel_file[ :bscan_elements ] = read_bscan_elements(f)
    channel_file[ :reportable_elements ] = read_reportable_elements(f)
    channel_file[ :indications ] = read_indications(f)
    channel_file[ :rescan_records ] = read_rescan_records(f)
    channel_file[ :bscan_records ] = read_bscan_records(f)
    channel_file[ :scan_file_records ] = read_scan_file_records(f)
  end
  channel_file
end

def usage
  puts "cf_reader.rb [--verbose] <filename>"
  exit
end

filename = nil
$verbose = false

ARGV.each do |a|
  if a == '--verbose'
    $verbose = true
  else
    usage unless filename.nil?
    filename = a
  end
end

usage if filename.nil?

puts read_channel_file(filename).to_yaml

