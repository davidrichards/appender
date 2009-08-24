require File.dirname(__FILE__) + '/spec_helper'

describe "Appender" do
  
  before do
    @config_file = "/tmp/appender_spec.conf"
    File.open(@config_file, 'w') {|f| f.write contents}
  end
  
  it "should be able to append a file with new contents" do
    Appender.process(:config_file => @config_file, :append => "New contents")
    File.read(@config_file).should match(/New contents$/)
  end
  
  it "should append new contents on a new line" do
    Appender.process(:config_file => @config_file, :append => "New contents")
    File.read(@config_file).should match(/^New contents$/)
  end
  
  it "should not try to work on missing files" do
    missing_file = 'not_a_file'
    File.should_not be_exist(missing_file)
    lambda{Appender.process(:config_file => missing_file)}.should raise_error(/No such file or directory/)
    File.should_not be_exist(missing_file)
  end
  
  it "should not complain if not appending anything" do
    lambda{Appender.process(:config_file => @config_file)}.should_not raise_error
  end
  
  it "should leave an identical file in place, even if it wasn't changed" do
    Appender.process(:config_file => @config_file)
    read_contents.should eql(contents)
  end
  
  it "should remove all lines that match a pattern" do
    Appender.process(:config_file => @config_file, :remove => '#')
    read_contents.should_not match(/\#/)
  end
  
  it "should remove the whole line, not just the matching portion of the remove parameter" do
    Appender.process(:config_file => @config_file, :remove => '#')
    read_contents.should eql(comment_less_expectation)
  end
  
  it "should change the stored content with the filtered results" do
    a = Appender.new
    a.process(:config_file => @config_file, :remove => '#')
    a.content.should eql(comment_less_expectation)
  end
  
  it "should be able to take an array of filters" do
    Appender.process(:config_file => @config_file, :remove => ['#', 'value'])
    read_contents.should eql(comment_and_value_less_expectation)
  end
  
  it "should be able to take regular expressions for filters" do
    Appender.process(:config_file => @config_file, :remove => [/#/, /value/])
    read_contents.should eql(comment_and_value_less_expectation)
  end
  
  it "should append the new contents after removing the matching contents" do
    read_contents.should match(/^key value/)
    Appender.process(:config_file => @config_file, :remove => /^key value/, :append => "key new_value")
    read_contents.should_not match(/^key value/)
    read_contents.should match(/^key new_value/)
  end
  
  it "should be able to remove excessive white space" do
    Appender.process(:config_file => @config_file, :remove => [/#/, /value/], :clean => true)
    read_contents.should eql(clean_expectation)
  end
  
  it "should log rotate the file, keep 5 versions of the configuration file in the directory" do
    STDOUT.sync = true
    puts "\n\n******************************\nRunning a 7-second spec\n******************************\n\n"
    7.times do 
      Appender.process(:config_file => @config_file)
      sleep 1 # Ensure a new timestamp
    end
    ls = `ls #{File.dirname(@config_file)}/#{File.split(@config_file).last}.*`.split("\n")
    ls.size.should eql(5)
  end
  
  it "should not break the original configuration file if it cannot be log rotated" do
    def LogRotate.rotate_file(*args); raise(StandardError, "Testing rotate_file"); end
    lambda{Appender.process(:config_file => @config_file, :append => "New contents")}.should 
      raise_error(StandardError, "Testing rotate_file")
    File.read(@config_file).should eql(contents)
  end

  after(:all) do
    `rm -rf /tmp/appender_spec.conf*`
  end
end

describe Appender, "Log Rotate" do
  
  before do
    @config_file = "/tmp/appender_spec.conf"
    File.open(@config_file, 'w') {|f| f.write contents}
  end

  # Running this on its own to reduce the side effects of stubbing out log rotation.
  it "should not break the original configuration file if it cannot be log rotated" do
    LogRotate.stub!(:rotate_file).and_return(lambda{raise(StandardError, "Testing rotate_file")})
    # def LogRotate.rotate_file(*args); raise(StandardError, ); end
    lambda{Appender.process(:config_file => @config_file, :append => "New contents")}.should 
      raise_error(StandardError, "Testing rotate_file")
    File.read(@config_file).should eql(contents)
  end
  
  after(:all) do
    `rm -rf /tmp/appender_spec.conf*`
  end
end


def read_contents
  File.read(@config_file)
end

def contents
  %{
# This is like a config file

# It has comments (this)

# It has key/value pairs:
key value

# It has some more-specific values that may be interesting to test
destination df_cron { file("/var/log/cron.log"); };

# It does NOT have trailing whitespace}
end

def comment_less_expectation
  %{


key value

destination df_cron { file("/var/log/cron.log"); };

}
end

def comment_and_value_less_expectation
  %{



destination df_cron { file("/var/log/cron.log"); };

}
end

def clean_expectation
  %{
destination df_cron { file("/var/log/cron.log"); };
}
end