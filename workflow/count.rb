#!/usr/bin/env ruby
# encoding: utf-8

files = ARGV[0].split "\t"

# placeholder for directories to expand into files
dirs = []

# check if directories are present
files.each { |filepath| dirs.push filepath if File.directory? filepath }

# expand directories into files back into the files array, only to avoid re-counting the total files later, since ImageOptim-CLI can handle directories perfectly
dirs.each do |dir|
  files.delete dir
  files = files.concat Dir.glob("#{dir}/**/*.{png,jpg,jpeg}")
end

puts "Optimizing #{files.count} #{files.count == 1 ? 'image' : 'images'}"