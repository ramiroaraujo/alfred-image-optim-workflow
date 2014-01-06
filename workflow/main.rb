#!/usr/bin/env ruby
# encoding: utf-8

require_relative 'bundle/bundler/setup'
require 'terminal-notifier'

files = ARGV[0].split "\t"

# basic check for dependencies, ImageAlpha and ImageOptim
has_image_alpha = File.exists?('/Applications/ImageAlpha.app')
has_image_optim = File.exists?('/Applications/ImageOptim.app')

if !has_image_alpha || !has_image_optim
  TerminalNotifier.notify('Please install it and re-run the workflow', :title => "Missing #{!has_image_alpha ? 'ImageAlpha' : 'ImageOptim'}", :group => Process.pid, :sender => 'com.runningwithcrayons.Alfred-2', :sound => 'Basso')
  exit
end

# actions
jpegmini = false # will use ImageMagick's mogrify at quality 75 if jpegmini is not present
imagealpha = false

# checks if JPEGs or PNGs are present, and enable jpeg-mini and ImageAlpha accordingly
files.each do |filepath|
  ext = File.extname(filepath)
  jpegmini = true if ext == '.jpg' || ext == '.jpeg'
  imagealpha = true if ext == '.png'
end

# joins back the files
selection = files.join "\n"

# runs ImageOptim-CLI
output = `echo "#{selection}" | bin/imageOptim #{'--jpeg-mini' if jpegmini} #{'--image-alpha' if imagealpha} --quit`

# outputs last line of feedback (and removes console formatting), which shows savings
puts output.split("\n")[-1].gsub(27.chr, '').gsub(/\[31m|\[32m|\[39m/, '')
