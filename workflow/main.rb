#!/usr/bin/env ruby
# encoding: utf-8

selection = ARGV[0].gsub "\t", "\n"

# si no hay jpgs, no poner jpeg-mini
# ver como fallar si no hay imageOptim o imageAlpha, y mostrar un error visible
# ver de usar una alternativa a jpeg-mini si no está instalado

`echo "#{selection}" | bin/imageOptim --jpeg-mini --image-alpha --quit`
