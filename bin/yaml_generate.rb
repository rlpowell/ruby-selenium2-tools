#!/usr/bin/ruby -w

def help
  puts <<-EOF
    #{$0} -f [file] -a [attr] -x [base_xpath] {-r} {-R [xpath_regex}

    -h, --help:
          Show help

    -f, --file:
          The html/xml file to read from

    -a, --attribute:
          The html element attribute to return yaml about

    -A, --attribute-value-regex:
          Only include those items where the attribute's value matches this regex

    -x, --base-xpath:
          The base xpath to start with when finding elements

    -r, --return-regex:
          Return a version of the attribute value that will be used as regular expression, i.e. convert various special characters

    -R, --xpath-regex:
          A regular expression to compare the generated xpaths to; if they don't match, that element is skipped.

    -H, --header:
          The name for the yaml section generated.

    -F, --regex-file:
          A yaml file with an array (for ordering) of "foo": "bar" entries, where foo is a Ruby regexp, and bar is what to replace it with.  These are applied to the attribute values before printing.

          As a particularily useful example, due conversion issues the following:

            - "\\\\n": ""

          will remove "newlines" from the output, and empty output segments are dropped, so this is very helpful.

          EOF
end

def return_ordered_text( elem )
  string = ""
  while elem
    # $stderr.print "elem: #{elem.class.name}, #{elem.inspect}\n"
    if elem.class == REXML::Text
      string += elem.to_s
    else
      string += return_ordered_text( elem.get_text )
    end
    elem = elem.next_sibling_node
  end

  return string
end

def recurse_over_elements(xpath_so_far, elem, attribute, xpath_regex, attribute_value_regex, return_regex, post_regexes)
  # Counters to make sure we number the xpath bits correctly
  counters = Hash.new
  elem.each do |subelem|
    if subelem.class == REXML::Element
      if counters.has_key?( subelem.name )
        counters[subelem.name] += 1
      else
        counters[subelem.name] = 1
      end

      new_xpath = "#{xpath_so_far}/#{subelem.name}[#{counters[subelem.name]}]"

      # Checks if it has the xpath we're interested in
      if new_xpath =~ Regexp.new(xpath_regex)
        attr_val = nil

        # Are we looking for the text bits?
        if attribute == "text"
          text = return_ordered_text( subelem.get_text )
          if text != ""
            #print "#{xpath_so_far}/#{subelem.name}[#{counters[subelem.name]}] #{subelem.inspect}\n"
            attr_val = text
          end
        else
          # Checks if it has the attribute we're interested in
          if subelem.attribute(attribute)
            #print "#{xpath_so_far}/#{subelem.name}[#{counters[subelem.name]}] #{subelem.inspect}\n"
            attr_val = subelem.attribute(attribute).to_s
          end
        end

        if attr_val
          attr_val.gsub!(/\&amp;/,'&')

          # Check if it has the sort of value we are interested in
          if attr_val !~ Regexp.new(attribute_value_regex)
            next
          end

          # Make regex changes
          if return_regex
            attr_val = Regexp.escape(attr_val)
          end

          # Make newlines easy to match
          attr_val.gsub!(/\n/, '\n')

          if post_regexes
            post_regexes.each do |pair|
              regex = pair.keys.first
              sub = pair.values.first
              attr_val.gsub!(Regexp.new(regex), sub)
            end
          end

          # Drop anything left that's just newlines
          attr_val.gsub!(/^(\\n)*$/, '')

          # If the regexes removed everything, don't print a
          # segment
          if attr_val != ""
            if attribute == "text"
              print %Q(  -\n    - "xpath"\n    - "#{new_xpath}"\n    - "#{attr_val}"\n)
            else
              print %Q(  -\n    - "xpath"\n    - "#{new_xpath}"\n    - "#{attribute}"\n    - "#{attr_val}"\n)
            end
          end
        end
      end
      recurse_over_elements(new_xpath, subelem, attribute, xpath_regex, attribute_value_regex, return_regex, post_regexes)
    end
  end
end

require 'rexml/document'
include REXML
require 'yaml'
require 'getoptlong'

orig_args = ARGV.join('" "')

opts = GetoptLong.new(
                      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
                      [ '--attribute', '-a', GetoptLong::REQUIRED_ARGUMENT ],
                      [ '--xpath-regex', '-R', GetoptLong::REQUIRED_ARGUMENT ],
                      [ '--attribute-value-regex', '-A', GetoptLong::REQUIRED_ARGUMENT ],
                      [ '--file', '-f', GetoptLong::REQUIRED_ARGUMENT ],
                      [ '--base-xpath', '-x', GetoptLong::REQUIRED_ARGUMENT ],
                      [ '--header', '-H', GetoptLong::REQUIRED_ARGUMENT ],
                      [ '--regex-file', '-F', GetoptLong::REQUIRED_ARGUMENT ],
                      [ '--return-regex', '-r', GetoptLong::NO_ARGUMENT ]
                     )

attribute = nil
xpath_regex = ".*"
attribute_value_regex = ".*"
file = nil
base_xpath = nil
return_regex = false
header = '!!NEW DATA FIX ME!!'
regex_file = nil

opts.each do |opt, arg|
  case opt
  when '--help'
    help
    exit 1
  when '--file'
    file = arg.to_s
  when '--attribute'
    attribute = arg.to_s
  when '--base-xpath'
    base_xpath = arg.to_s
  when '--xpath-regex'
    xpath_regex = arg.to_s
  when '--attribute-value-regex'
    attribute_value_regex = arg.to_s
  when '--header'
    header = arg.to_s
  when '--regex-file'
    regex_file = arg.to_s
  when '--return-regex'
    return_regex = true
  end
end

if attribute == nil or file == nil or base_xpath == nil
  help
  exit 1
end

xmlfile = File.new(file)
xmldoc = Document.new(xmlfile)

print "\n\n#################################################################################\n"
print "# BEGIN AUTOGENERATED BY #{$0} with arguments: \n"
print "# \"#{orig_args}\"\n"
print "#################################################################################\n"
print "#{header}:\n"

post_regexes = Array.new

if regex_file
  post_regexes = File.open( regex_file ) { |yf| YAML::load( yf ) }
end

XPath.each(xmldoc, base_xpath) do |elem|
  recurse_over_elements(base_xpath, elem, attribute, xpath_regex, attribute_value_regex, return_regex, post_regexes)
end

print "#################################################################################\n"
print "#   END AUTOGENERATED BY #{$0}\n"
print "#################################################################################\n\n"
