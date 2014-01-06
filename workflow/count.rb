#!/usr/bin/env ruby
# encoding: utf-8

files = ARGV[0].split "\t"

puts "Optimizing #{files.count} #{files.count == 1 ? 'image' : 'images'}"