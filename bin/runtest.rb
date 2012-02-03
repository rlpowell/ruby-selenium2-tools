#!/bin/env ruby
#
# This exists because options have to be passed to rspec as
# environment variables, which I find clunky.
#
# yaml/runtest.yaml is its config file

require 'rubygems'
require 'getoptlong'
require 'yaml'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--port', '-p', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--browser', '-b', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--server', '-s', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--experiment', '-e', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--release', '-r', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--skip-sections', '-S', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--debug', '-D', GetoptLong::OPTIONAL_ARGUMENT ]
)

$config = {}
$config['port'] = 4444
$config['browser'] = 'firefox'
$config['server'] = nil
$config['release'] = nil
$config['skip'] = nil
$config['experiment'] = nil
$config['debug'] = false

# Override defaults with values from config file
$config.merge!( File.open( "yaml/runtest.yaml" ) { |yf| YAML::load( yf ) } )

def usage
  puts <<-EOF
  
./runtest [optional arguments]

Optional Arguments:

  --port/-p		port to reach selenium on; default: #{$config['port']}
  --browser/-b		browser; default: #{$config['browser']}
  --server/-s		server to test against; default: #{$config['server']}
  --experiment/-e	experiment to run; default: #{$config['experiment']}
  --skip-sections/-S	sections to skip; example: "Heatmap,Histogram"; see the yaml/000*.yaml files for section lists; default: #{$config['skip'].to_s}
  --release/-r		software release to expect; this is an artificial string only used here; default: #{$config['release']}
                        available choices: #{$config['releases'].join(', ')}
  --debug/-D		debug mode; default #{$config['debug']}

  EOF

  exit 1
end

opts.each do |opt, arg|
  case opt
    when '--help'
      usage
    when '--debug'
      $config['debug'] = true
    when '--port'
      $config['port'] = arg
    when '--browser'
      $config['browser'] = arg
    when '--server'
      $config['server'] = arg
    when '--experiment'
      $config['experiment'] = arg
    when '--release'
      $config['release'] = arg
    when '--skip-sections'
      $config['skip'] = arg
  end
end

ENV['PORT']=$config['port'].to_s
ENV['BROWSER']=$config['browser'].to_s
ENV['SERVER']=$config['server'].to_s
ENV['EXPERIMENT']=$config['experiment'].to_s
ENV['RELEASE']=$config['release'].to_s
ENV['SKIP']=$config['skip'].to_s
ENV['DEBUG']=$config['debug'].to_s

if $config['debug']
  exec( "rlwrap", "rspec", "#{$0}/../wrapper.rb" )
else
  exec( "rspec", "#{$0}/../wrapper.rb" )
end
