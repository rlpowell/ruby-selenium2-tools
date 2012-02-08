require 'rubygems'
gem 'selenium-webdriver'
require "selenium-webdriver"
require 'rspec'
require 'ruby-debug'
require 'yaml'

require 'rspec/core/formatters/documentation_formatter'

# RSpec setup
RSpec.configure do |config|
  config.mock_with :rspec
  config.color_enabled = true
  config.formatter = RSpec::Core::Formatters::DocumentationFormatter
end

# Deal with environment arguments
if ENV['DEBUG'] == 'true'
  $debug = true
else
  $debug = false
end
$port = ENV['PORT']
$browser = ENV['BROWSER']
$test_set = ENV['TEST_SET']
$extra_config = YAML::load(ENV['CONFIG'])

def check_conditions(conditions)
  conditions.each do |condition|
    check_condition(condition) or return false
  end
  return true
end

def check_condition(condition)
  value=$yaml_data[condition[0]] == condition[1]
  $debug and puts "In check_condition: #{condition.inspect}, which is #{value.inspect}; #{condition[0]}, #{$yaml_data[condition[0]]} == #{condition[1]}\n"
  return $yaml_data[condition[0]] == condition[1]
end

require 'GeneralSeleniumUtility.rb'
include GeneralSeleniumUtility

# Load our own config
$yaml_data = load_yaml_data("yaml/wrapper.yaml")
$yaml_data['test_set'] = $test_set
$yaml_data['port'] = $port
$yaml_data['browser'] = $browser
if $yaml_data['wrapper_modules']
  $yaml_data['wrapper_modules'].each do |module_name|
    $debug and print "adding #{module_name}.rb\n"
    require "lib/#{module_name}.rb"
    include Module.const_get(module_name)
  end
end

# First we load the setup files, which start with numbers, then
# we load the section files they point at
Dir.glob("yaml/[0-9]*.yaml").sort.each do |file|
  $debug and puts "wrapper considering loading file: #{file}\n"
  data = load_yaml_data(file)
  if data['conditions']
    check_conditions(data['conditions']) or next
  end

  $debug and print "yaml_data before #{file}: #{$yaml_data.inspect}\n"
  puts "Loading data from #{file}\n"
  data.delete('conditions')
  $yaml_data.merge!(data)
  $debug and print "yaml_data after #{file}: #{$yaml_data.inspect}\n"
  #load_yaml_data( ENV['YAML_START_FILE'] )
  #@yaml_data['yaml_files'].each do |file|
  #  load_yaml_data( file )
end

# Trim out any sections the user doesn't want
$debug and puts "Skipping: #{ENV['SKIP']}\n"
ENV['SKIP'].split(/,/).each do |skip|
  $yaml_data['sections'].delete(skip)
end
$debug and puts "sections to use: #{$yaml_data['sections'].inspect}\n"

if ! $yaml_data['sections']
  print "NO SECTIONS DEFINED in yaml/\n"
  exit 1
end

# Now we loop over the sections
$yaml_data['sections'].each do |section|
  Dir.glob("yaml/#{section}*.yaml").each do |file|
    $debug and puts "wrapper considering loading file: #{file}\n"
    data = load_yaml_data(file)
    if data['conditions']
      check_conditions(data['conditions']) or next
    end

    $debug and puts "wrapper actually loading file: #{file}\n"
    #print "yaml_data before #{file}: #{$yaml_data.inspect}\n"
    puts "Loading data from #{file}\n"
    data.delete('conditions')
    $yaml_data.merge!(data)
    #print "yaml_data after #{file}: #{$yaml_data.inspect}\n"
  end
end

# Now load in any special config
$yaml_data.merge!($extra_config)

describe "wrapper" do
  include GeneralSeleniumUtility
  if $yaml_data['wrapper_modules']
    $yaml_data['wrapper_modules'].each do |module_name|
      $debug and print "adding #{module_name}.rb\n"
      require "lib/#{module_name}.rb"
      include Module.const_get(module_name)
    end
  end

  before(:all) do
    @debug = $debug
    @port = $port
    @browser = $browser
    @test_set = $test_set
    @yaml_data = $yaml_data

    selenium_setup

  end

  $yaml_data['sections'].each do |section|
    print "Running tests from #{section}.rb\n"
    require "tests/#{section}.rb"
    include Module.const_get(section)
  end

  after(:all) do
    @debug or @driver.quit
  end
end
