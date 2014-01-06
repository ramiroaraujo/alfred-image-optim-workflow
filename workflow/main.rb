#!/usr/bin/env ruby
# encoding: utf-8

files = ARGV[0].split "\t"

#actions
jpegmini = false # will use ImageMagick's mogrify at quality 75 if jpegmini is not present
imagealpha = false

# checks if JPEGs or PNGs are present, and enable jpeg-mini and ImageAlpha accordingly
files.each do |filepath|
  ext = File.extname(filepath)
  jpegmini = true if ext == 'jpg' || ext == 'jpeg'
  imagealpha = true if ext == 'png'
end

selection = files.join "\n"

output = `echo "#{selection}" | bin/imageOptim #{'--jpeg-mini' if jpegmini} #{'--image-alpha' if imagealpha} --quit`