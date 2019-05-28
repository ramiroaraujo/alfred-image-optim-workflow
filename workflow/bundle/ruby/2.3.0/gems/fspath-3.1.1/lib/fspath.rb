# frozen_string_literal: true

require 'pathname'
require 'tempfile'
require 'tmpdir'
require 'fcntl'

# Extension of Pathname with helpful methods and fixes
class FSPath < Pathname
  # Extension of Tempfile returning instance of provided class for path
  class Tempfile < ::Tempfile
    # Eats first argument which must be a class, and calls super
    def initialize(path_klass, *args)
      unless path_klass.is_a?(Class)
        fail ArgumentError, "#{path_klass.inspect} is not a class"
      end

      @path_klass = path_klass
      super(*args)
    end

    # Returns path wrapped in class provided in initialize
    def path
      @path_klass.new(super)
    end

    # Fixes using appropriate initializer for jruby in 1.8 mode, also returns
    # result of block in ruby 1.8
    def self.open(*args)
      tempfile = new(*args)

      if block_given?
        begin
          yield(tempfile)
        ensure
          tempfile.close
        end
      else
        tempfile
      end
    end
  end

  class << self
    # Return current user home path if called without argument.
    # If called with argument return specified user home path.
    def ~(name = nil)
      new(File.expand_path("~#{name}"))
    end

    # Returns common dir for paths
    def common_dir(*paths)
      fail ArgumentError, 'At least one path is required' if paths.empty?

      paths.map do |path|
        new(path).dirname.ascendants
      end.inject(:&).first
    end

    # Returns or yields temp file created by Tempfile.new with path returning
    # FSPath
    def temp_file(prefix_suffix = nil, *args, &block)
      prefix_suffix = fix_prefix_suffix(prefix_suffix || 'f')
      Tempfile.open(self, prefix_suffix, *args, &block)
    end

    # Returns or yields path as FSPath of temp file created by Tempfile.new
    # WARNING: loosing reference to returned object will remove file on nearest
    # GC run
    def temp_file_path(prefix_suffix = nil, *args)
      if block_given?
        temp_file(prefix_suffix, *args) do |file|
          file.close
          yield file.path
        end
      else
        file = temp_file(prefix_suffix, *args)
        file.close
        path = file.path
        path.instance_variable_set(:@__temp_file, file)
        path
      end
    end

    # Returns or yields FSPath with temp directory created by Dir.mktmpdir
    def temp_dir(prefix_suffix = nil, *args)
      prefix_suffix = fix_prefix_suffix(prefix_suffix || 'd')
      if block_given?
        Dir.mktmpdir(prefix_suffix, *args) do |dir|
          yield new(dir)
        end
      else
        new(Dir.mktmpdir(prefix_suffix, *args))
      end
    end

  private

    def fix_prefix_suffix(prefix_suffix)
      if prefix_suffix.is_a?(Array)
        prefix_suffix.map(&:to_s)
      else
        prefix_suffix.to_s
      end
    end
  end

  # Join paths using File.join
  def /(other)
    self.class.new(File.join(@path, other.to_s))
  end

  unless (new('a') + 'b').is_a?(self)
    # Fixing Pathname#+
    def +(other)
      self.class.new(super)
    end
  end

  # Return basename without ext and ext as two-element array
  def prefix_suffix
    ext = extname
    [basename(ext), ext]
  end

  # Calls class method with prefix and suffix set using prefix_suffix
  def temp_file(*args, &block)
    self.class.temp_file(prefix_suffix, *args, &block)
  end

  # Calls class method with prefix and suffix set using prefix_suffix
  def temp_file_path(*args, &block)
    self.class.temp_file_path(prefix_suffix, *args, &block)
  end

  # Calls class method with prefix and suffix set using prefix_suffix
  def temp_dir(*args, &block)
    self.class.temp_dir(prefix_suffix, *args, &block)
  end

  # Fixing Pathname.relative_path_from
  def relative_path_from(other)
    self.class.new(super(self.class.new(other)))
  end

  unless Pathname.method_defined?(:binread)
    # Read data from file opened in binary mode
    def binread(length = nil, offset = nil)
      open('rb') do |f|
        f.seek(offset) if offset
        f.read(length)
      end
    end
  end

  unless Pathname.method_defined?(:write)
    # Write data to file
    def write(data, offset = nil)
      _write(data, offset, false)
    end
  end

  unless Pathname.method_defined?(:binwrite)
    # Write data to file opened in binary mode
    def binwrite(data, offset = nil)
      _write(data, offset, true)
    end
  end

  # Append data to file
  def append(data)
    open('a') do |f|
      f.write(data)
    end
  end

  # Append data to file opened in binary mode
  def binappend(data)
    open('ab') do |f|
      f.write(data)
    end
  end

  # Escape characters in glob pattern
  def escape_glob
    self.class.new(escape_glob_string)
  end

  # Expand glob
  def glob(*args, &block)
    flags = args.last.is_a?(Integer) ? args.pop : nil
    args = [File.join(escape_glob_string, *args)]
    args << flags if flags
    self.class.glob(*args, &block)
  end

  # Returns list of elements in the given path in ascending order
  def ascendants
    paths = []
    path = @path
    paths << self
    while (r = chop_basename(path))
      path = r.first
      break if path.empty?

      paths << self.class.new(del_trailing_separator(path))
    end
    paths
  end

  # Returns list of elements in the given path in descending order
  def descendants
    ascendants.reverse
  end

  # Iterates over and yields each element in the given path in ascending order
  def ascend(&block)
    paths = ascendants
    paths.each(&block) if block
    paths
  end

  # Iterates over and yields each element in the given path in descending order
  def descend(&block)
    paths = descendants
    paths.each(&block) if block
    paths
  end

  # Returns path parts
  #   FSPath('/a/b/c').parts    # ['/', 'a', 'b', 'c']
  #   FSPath('a/b/c').parts     # ['a', 'b', 'c']
  #   FSPath('./a/b/c').parts   # ['.', 'a', 'b', 'c']
  #   FSPath('a/../b/c').parts  # ['a', '..', 'b', 'c']
  def parts
    prefix, parts = split_names(@path)
    prefix.empty? ? parts : [prefix] + parts
  end

  unless pwd.is_a?(self)
    # Fixing glob
    def self.glob(*args)
      if block_given?
        super do |f|
          yield new(f)
        end
      else
        super.map{ |f| new(f) }
      end
    end

    # Fixing getwd
    def self.getwd
      new(super)
    end

    # Fixing pwd
    def self.pwd
      new(super)
    end

    # Fixing basename
    def basename(*args)
      self.class.new(super)
    end

    # Fixing dirname
    def dirname
      self.class.new(super)
    end

    # Fixing expand_path
    def expand_path(*args)
      self.class.new(super)
    end

    # Fixing split
    def split
      super.map{ |f| self.class.new(f) }
    end

    # Fixing sub
    def sub(pattern, *rest, &block)
      self.class.new(super)
    end

    if Pathname.method_defined?(:sub_ext)
      # Fixing sub_ext
      def sub_ext(ext)
        self.class.new(super)
      end
    end

    # Fixing realpath
    def realpath
      self.class.new(super)
    end

    if Pathname.method_defined?(:realdirpath)
      # Fixing realdirpath
      def realdirpath
        self.class.new(super)
      end
    end

    # Fixing readlink
    def readlink
      self.class.new(super)
    end

    # Fixing each_entry
    def each_entry
      super do |f|
        yield self.class.new(f)
      end
    end

    # Fixing entries
    def entries
      super.map{ |f| self.class.new(f) }
    end
  end

  unless new('a').inspect.include?('FSPath')
    # Fixing inspect
    def inspect
      "#<#{self.class}:#{@path}>"
    end
  end

private

  def escape_glob_string
    @path.gsub(/([\*\?\[\]\{\}])/, '\\\\\1')
  end

  def _write(data, offset, binmode)
    mode = if offset
      Fcntl::O_CREAT | Fcntl::O_RDWR # fix for jruby 1.8 truncating with WRONLY
    else
      Fcntl::O_CREAT | Fcntl::O_WRONLY | Fcntl::O_TRUNC
    end

    File.open(@path, mode) do |f|
      f.binmode if binmode
      f.seek(offset) if offset
      f.write(data)
    end
  end
end

# Add FSPath method as alias to FSPath.new
module Kernel
private # rubocop:disable Layout/IndentationWidth

  # FSPath(path) method
  define_method :FSPath do |path|
    FSPath.new(path)
  end
end
