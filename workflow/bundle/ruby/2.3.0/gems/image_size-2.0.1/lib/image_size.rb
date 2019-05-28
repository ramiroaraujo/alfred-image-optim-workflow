# encoding: BINARY
# frozen_string_literal: true

require 'stringio'

# Determine image format and size
class ImageSize
  class FormatError < StandardError; end

  # Array joining with 'x'
  class Size < Array
    # join using 'x'
    def to_s
      join('x')
    end
  end

  class ImageReader # :nodoc:
    attr_reader :data
    def initialize(data_or_io)
      @io = if data_or_io.is_a?(String)
        StringIO.new(data_or_io)
      elsif data_or_io.respond_to?(:read) && data_or_io.respond_to?(:eof?)
        data_or_io
      else
        raise ArgumentError, "expected data as String or an object responding to read and eof?, got #{data_or_io.class}"
      end
      @data = String.new # not frozen
    end

    CHUNK = 1024
    def [](offset, length)
      while !@io.eof? && @data.length < offset + length
        data = @io.read(CHUNK)
        break unless data

        data.force_encoding(@data.encoding) if data.respond_to?(:encoding)
        @data << data
      end
      @data[offset, length]
    end
  end

  # Given path to image finds its format, width and height
  def self.path(path)
    File.open(path, 'rb'){ |f| new(f) }
  end

  # Used for svg
  def self.dpi
    @dpi || 72
  end

  # Used for svg
  def self.dpi=(dpi)
    @dpi = dpi.to_f
  end

  # Given image as any class responding to read and eof? or data as String, finds its format and dimensions
  def initialize(data)
    ir = ImageReader.new(data)
    @format = detect_format(ir)
    return unless @format

    @width, @height = send("size_of_#{@format}", ir)
  end

  # Image format
  attr_reader :format

  # Image width
  attr_reader :width
  alias_method :w, :width

  # Image height
  attr_reader :height
  alias_method :h, :height

  # get image width and height as an array which to_s method returns "#{width}x#{height}"
  def size
    Size.new([width, height]) if format
  end

private

  SVG_R = /<svg\b([^>]*)>/.freeze
  def detect_format(ir)
    head = ir[0, 1024]
    case
    when head[0, 6] =~ /GIF8[79]a/          then :gif
    when head[0, 8] == "\211PNG\r\n\032\n"  then detect_png_type(ir)
    when head[0, 8] == "\212MNG\r\n\032\n"  then :mng
    when head[0, 2] == "\377\330"           then :jpeg
    when head[0, 2] == 'BM'                 then :bmp
    when head[0, 2] =~ /P[1-7]/             then :ppm
    when head =~ /\#define\s+\S+\s+\d+/     then :xbm
    when head[0, 4] == "II*\000"            then :tiff
    when head[0, 4] == "MM\000*"            then :tiff
    when head =~ %r{/\* XPM \*/}            then :xpm
    when head[0, 4] == '8BPS'               then :psd
    when head[0, 3] =~ /[FC]WS/             then :swf
    when head[SVG_R] ||
      head =~ /<\?xml|<!--/ && ir[0, 4096][SVG_R]
                                            then :svg
    when head[0, 2] =~ /\n[\000-\005]/      then :pcx
    when head[0, 12] =~ /RIFF(?m:....)WEBP/ then :webp
    when head[0, 4] == "\000\000\001\000"   then :ico
    when head[0, 4] == "\000\000\002\000"   then :cur
    end
  end

  def detect_png_type(ir)
    offset = 8
    loop do
      type = ir[offset + 4, 4]
      break if ['IDAT', 'IEND', nil].include?(type)
      return :apng if type == 'acTL'

      length = ir[offset, 4].unpack('N')[0]
      offset += 8 + length + 4
    end
    :png
  end

  def size_of_gif(ir)
    ir[6, 4].unpack('vv')
  end

  def size_of_mng(ir)
    unless ir[12, 4] == 'MHDR'
      raise FormatError, 'MHDR not in place for MNG'
    end

    ir[16, 8].unpack('NN')
  end

  def size_of_png(ir)
    unless ir[12, 4] == 'IHDR'
      raise FormatError, 'IHDR not in place for PNG'
    end

    ir[16, 8].unpack('NN')
  end
  alias_method :size_of_apng, :size_of_png

  JPEG_CODE_CHECK = %W[
    \xC0 \xC1 \xC2 \xC3
    \xC5 \xC6 \xC7
    \xC9 \xCA \xCB
    \xCD \xCE \xCF
  ].freeze
  def size_of_jpeg(ir)
    section_marker = "\xFF"
    offset = 2
    loop do
      offset += 1 until [nil, section_marker].include? ir[offset, 1]
      offset += 1 until section_marker != ir[offset + 1, 1]
      raise FormatError, 'EOF in JPEG' if ir[offset, 1].nil?

      _marker, code, length = ir[offset, 4].unpack('aan')
      offset += 4

      if JPEG_CODE_CHECK.include?(code)
        return ir[offset + 1, 4].unpack('nn').reverse
      end

      offset += length - 2
    end
  end

  def size_of_bmp(ir)
    header_size = ir[14, 4].unpack('V')[0]
    if header_size == 12
      ir[18, 4].unpack('vv')
    else
      ir[18, 8].unpack('VV').map do |n|
        if n > 0x7fff_ffff
          0x1_0000_0000 - n # absolute value of converted to signed
        else
          n
        end
      end
    end
  end

  def size_of_ppm(ir)
    header = ir[0, 1024]
    header.gsub!(/^\#[^\n\r]*/m, '')
    header =~ /^(P[1-6])\s+?(\d+)\s+?(\d+)/m
    case $1
    when 'P1', 'P4' then @format = :pbm
    when 'P2', 'P5' then @format = :pgm
    end
    [$2.to_i, $3.to_i]
  end

  def size_of_xbm(ir)
    ir[0, 1024] =~ /^\#define\s*\S*\s*(\d+)\s*\n\#define\s*\S*\s*(\d+)/mi
    [$1.to_i, $2.to_i]
  end

  def size_of_xpm(ir)
    length = 1024
    until (data = ir[0, length]) =~ /"\s*(\d+)\s+(\d+)(\s+\d+\s+\d+){1,2}\s*"/m
      if data.length != length
        raise FormatError, 'XPM size not found'
      end

      length += 1024
    end
    [$1.to_i, $2.to_i]
  end

  def size_of_psd(ir)
    ir[14, 8].unpack('NN').reverse
  end

  def size_of_tiff(ir)
    endian2b = ir[0, 4] == "II*\000" ? 'v' : 'n'
    endian4b = endian2b.upcase
    packspec = [nil, 'C', nil, endian2b, endian4b, nil, 'c', nil, endian2b, endian4b]

    offset = ir[4, 4].unpack(endian4b)[0]
    num_dirent = ir[offset, 2].unpack(endian2b)[0]
    offset += 2
    num_dirent = offset + (num_dirent * 12)

    width = height = nil
    until width && height
      ifd = ir[offset, 12]
      raise FormatError, 'Reached end of directory entries in TIFF' if ifd.nil? || offset > num_dirent

      tag, type = ifd.unpack(endian2b * 2)
      offset += 12

      next if packspec[type].nil?

      value = ifd[8, 4].unpack(packspec[type])[0]
      case tag
      when 0x0100
        width = value
      when 0x0101
        height = value
      end
    end
    [width, height]
  end

  def size_of_pcx(ir)
    parts = ir[4, 8].unpack('S4')
    [parts[2] - parts[0] + 1, parts[3] - parts[1] + 1]
  end

  def size_of_swf(ir)
    value_bit_length = ir[8, 1].unpack('B5').first.to_i(2)
    bit_length = 5 + value_bit_length * 4
    rect_bits = ir[8, bit_length / 8 + 1].unpack("B#{bit_length}").first
    values = rect_bits.unpack('@5' + "a#{value_bit_length}" * 4).map{ |bits| bits.to_i(2) }
    x_min, x_max, y_min, y_max = values
    [(x_max - x_min) / 20, (y_max - y_min) / 20]
  end

  def size_of_svg(ir)
    attributes = {}
    ir.data[SVG_R, 1].scan(/(\S+)=(?:'([^']*)'|"([^"]*)"|([^'"\s]*))/) do |name, v0, v1, v2|
      attributes[name] = v0 || v1 || v2
    end
    dpi = self.class.dpi
    [attributes['width'], attributes['height']].map do |length|
      next unless length

      pixels = case length.downcase.strip[/(?:em|ex|px|in|cm|mm|pt|pc|%)\z/]
      when 'em', 'ex', '%' then nil
      when 'in' then length.to_f * dpi
      when 'cm' then length.to_f * dpi / 2.54
      when 'mm' then length.to_f * dpi / 25.4
      when 'pt' then length.to_f * dpi / 72
      when 'pc' then length.to_f * dpi / 6
      else length.to_f
      end
      pixels.round if pixels
    end
  end

  def size_of_ico(ir)
    ir[6, 2].unpack('CC').map{ |v| v.zero? ? 256 : v }
  end
  alias_method :size_of_cur, :size_of_ico

  def size_of_webp(ir)
    case ir[12, 4]
    when 'VP8 '
      ir[26, 4].unpack('vv').map{ |v| v & 0x3fff }
    when 'VP8L'
      n = ir[21, 4].unpack('V')[0]
      [(n & 0x3fff) + 1, (n >> 14 & 0x3fff) + 1]
    when 'VP8X'
      w16, w8, h16, h8 = ir[24, 6].unpack('vCvC')
      [(w16 | w8 << 16) + 1, (h16 | h8 << 16) + 1]
    end
  end
end
