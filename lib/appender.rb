#!/usr/bin/env ruby

# Appends a configuration file, rotating the file for safety.
class Appender

  require 'rubygems'
  require 'fileutils'
  require 'yaml'
  require 'ostruct'
  require 'logrotate'
  
  def self.process(options={})
    appender = new
    appender.process(options)
  end

  # Usage:
  # append_text = %{# Some configuration
  # Usually on multiple lines
  # key value
  # etc etc...
  # }
  # Appender.process(
  #  :config_file => '/etc/syslog-ng/syslog-ng.conf', 
  #  :append => append_text, 
  #  :remove => [/^etc/, /^Usually on multiple lines/]
  # )
  def process(options={})
    rotate_file(options[:config_file])
    clean_file(options[:remove])
    new_content = options[:append]
    new_content ||= options[:content]
    append_file(new_content)
    clean_white_space if options[:clean]
    ensure_file
  end
  alias :call :process
  
  # The contents to work with.
  attr_reader :content
  
  # The file we are working on.
  attr_reader :config_file
  
  # The directory where the configuration file is stored.
  attr_reader :output_directory
  
  protected
  
    # Makes sure at least the original contents are in place
    def ensure_file
      return if File.exist?(self.config_file)
      File.open(self.config_file, 'w') { |f| f.write(self.content) }
    end
  
    def log_options
      {
        :date_time_ext => true,
        :directory => self.output_directory,
        :date_time_format => '%F_%T',
        :count => 25
      }
    end
    
    def append_file(content)
      return true unless content
      self.content << "\n" unless self.content[-1].chr == "\n"
      self.content << content
      write_content_to_file
      true
    end
    
    def write_content_to_file
      File.open(self.config_file, 'w+') {|f| f.write(self.content)}
    end
    
    def clean_file(expressions)
      expressions = Array(expressions)
      expressions.delete_if {|e| e.nil? or (e.is_a?(String) and e.empty?)}
      return true if expressions.empty?
      expressions.map! {|e| Regexp.new(e)}
      
      new_content = ''
      self.content.each_line do |line|
        new_content << line unless expressions.any? {|e| line =~ e}
      end
      
      # Makes sure the internal state and the external state both reflect the
      # filtered contents. 
      @content = new_content
      File.open(self.config_file, 'w') {|f| f.write(new_content)}
      true
    end
  
    # Removes multiple blank rows in a row
    def clean_white_space
      @content.gsub!(/\n{2,}/, "\n")
      write_content_to_file
    end
    
    # Rotates the config file
    def rotate_file(config_file)
      config_file = nil if config_file.is_a?(String) and config_file.empty?
      raise ArgumentError, "Must provide a configuration file: config_file => 'some_file.conf'" unless
        config_file
        
      @content = File.read(config_file)
      
      LogRotate.rotate_file(config_file, self.log_options)

      @config_file = File.expand_path(config_file)
      @output_directory = File.dirname(@config_file)
      true
    end
  
end
