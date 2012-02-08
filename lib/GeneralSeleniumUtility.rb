#****************************************************
#
# General Notes
#
# Everything in here expects to be run under rspec.
#
# A lot of functions here take "how" and "what" as their first
# arguments, or similar.  These are selenium locator segments; the
# first is the locator type (:xpath most of the time, or :id or
# whatever); see
# http://selenium.googlecode.com/svn/trunk/docs/api/rb/Selenium/WebDriver/SearchContext.html#find_element-instance_method
# for a complete list.
#
# A lot also take a "tag_name" along with the "how" and "what"; this
# means that they'll check that the "how" and "what" selector points
# to a tag with the given tag name, as a basic sanity check.
#
# General documentation on the Selenium2 bindings for Ruby, which
# this code is a wrapper around, is at
# http://code.google.com/p/selenium/wiki/RubyBindings and
# http://selenium.googlecode.com/svn/trunk/docs/api/rb/index.html
#****************************************************
module GeneralSeleniumUtility

  #****************
  # Given the value of @browser, opens the browser as a remote
  # SeleniumWebdriver instance, and stores it in @driver
  #****************
  def selenium_setup
    if @browser.to_sym == :chrome
      @debug and print "I THINK I AM CHROME\n"
      caps = Selenium::WebDriver::Remote::Capabilities.chrome
      caps['chrome.switches'] = %w[--ignore-certificate-errors]

      @driver = Selenium::WebDriver.for( :remote,  :url => "http://localhost:#{@port}/wd/hub",
                                        :desired_capabilities => caps)
    elsif @browser.to_sym == :ffnonative
      @debug and print "I THINK I AM FIREFOX, NO NATIVE EVENTS\n"
      profile = Selenium::WebDriver::Firefox::Profile.new
      @debug and print "profile: #{profile.inspect}\n"
      # See http://code.google.com/p/selenium/issues/detail?id=3154
      profile['toolkit.telemetry.prompted'] = '2'
      profile['toolkit.telemetry.enabled'] = 'true'
      profile['toolkit.telemetry.rejected'] = 'false'
      profile.native_events = false
      @debug and print "profile: #{profile.inspect}\n"
        
      caps = Selenium::WebDriver::Remote::Capabilities.firefox(:firefox_profile => profile,
                                                               :browser_name          => "firefox",
                                                               :javascript_enabled    => true,
                                                               :takes_screenshot      => true,
                                                               :css_selectors_enabled => true,
                                                               :native_events         => false
                                                              )
      @driver = Selenium::WebDriver.for( :remote,  :url => "http://localhost:#{@port}/wd/hub",
                                        :desired_capabilities => caps)

      print "HANDLING OF THE MOZILLA TELEMETRY QUESTION IS BROKEN.  Please answer it manually, and hit return when done: "
      File.open("/dev/tty", "r").gets
    elsif @browser.to_sym == :ffnative
      @debug and print "I THINK I AM FIREFOX, NATIVE EVENTS ONLY\n"
      profile = Selenium::WebDriver::Firefox::Profile.new
      @debug and print "profile: #{profile.inspect}\n"
      # See http://code.google.com/p/selenium/issues/detail?id=3154
      profile['toolkit.telemetry.prompted'] = '2'
      profile['toolkit.telemetry.enabled'] = 'true'
      profile['toolkit.telemetry.rejected'] = 'false'
      profile.native_events = true
      @debug and print "profile: #{profile.inspect}\n"
        
      caps = Selenium::WebDriver::Remote::Capabilities.firefox(:firefox_profile => profile,
                                                               :browser_name          => "firefox",
                                                               :javascript_enabled    => true,
                                                               :takes_screenshot      => true,
                                                               :css_selectors_enabled => true,
                                                               :native_events         => true
                                                              )
      @driver = Selenium::WebDriver.for( :remote,  :url => "http://localhost:#{@port}/wd/hub",
                                        :desired_capabilities => caps)

      print "HANDLING OF THE MOZILLA TELEMETRY QUESTION IS BROKEN.  Please answer it manually, and hit return when done: "
      File.open("/dev/tty", "r").gets
    else
      @driver = Selenium::WebDriver.for( :remote,  :url => "http://localhost:#{@port}/wd/hub",
                                        :desired_capabilities => @browser.to_sym )
    end
  end

  #****************
  # pulls yaml from the given file name and returns it
  #****************
  def load_yaml_data( file )
    yaml_data = {}
    yaml_data.merge!( File.open( file ) { |yf| YAML::load( yf ) } )
    return yaml_data
  end

  #****************
  # Go to the page url given by the yaml_data key
  #****************
  def go_to(yaml_data_key)
    @driver.navigate.to $yaml_data[yaml_data_key][0]
    quiesce
    @driver.current_url.should =~ Regexp.new($yaml_data[yaml_data_key][1], Regexp::MULTILINE)
  end

  #****************
  # Finds the given element, checks its name, and types data into
  # the element
  #****************
  def check_element_send_keys(yaml_data_key)
      check_element_send_keys_raw(
        $yaml_data[yaml_data_key][0].to_sym,
        $yaml_data[yaml_data_key][1],
        $yaml_data[yaml_data_key][2],
        $yaml_data[yaml_data_key][3]
      )
  end
  def check_element_send_keys_raw(how, what, tag_name, to_type)
    e = @driver.find_element(how, what)
    e.tag_name.should == tag_name
    3.times do |x|
      e.clear
      e.send_keys(to_type)
      if e['value'] == to_type
        break
      else
        sleep 1
      end
    end
    e['value'].should == to_type
    return e
  end

  #****************
  # Find the element, check the tag name, click on it, check that
  # the URL we end up at after the click is what we expect and,
  # optionally, eat an alert that comes up.
  #****************
  def check_element_click(yaml_data_key)
      check_element_click_raw(
        $yaml_data[yaml_data_key][0].to_sym,
        $yaml_data[yaml_data_key][1],
        $yaml_data[yaml_data_key][2],
        $yaml_data[yaml_data_key][3],
        $yaml_data[yaml_data_key][4]
      )
  end
  def check_element_click_raw(how, what, tag_name, resulting_url, alert_text = nil)
    has_dealt_with_alert = false

    e = @driver.find_element(how, what)
    e.tag_name.should == tag_name
    e.click.should be_nil

    # Give it a few chances here
    10.times do 
      # this sometimes fails due to popups, at least on chrome
      begin
        quiesce
      rescue Exception => e
        @debug and print "Got exception in check_element_click: #{e}\n"

        if alert_text and not has_dealt_with_alert
          eat_alert( alert_text )
          has_dealt_with_alert = true
        end
      end
      if @driver.current_url =~ Regexp.new(resulting_url, Regexp::MULTILINE)
        break
      end
      sleep 5
      print '#'
    end

    if alert_text and not has_dealt_with_alert
      eat_alert( alert_text )
      has_dealt_with_alert = true
    end

    check_url_match(resulting_url)
    return e
  end

  #****************
  # Click on the given element
  #
  # It's called "no_move" because there's no expectation of a page
  # transition for these clicks, i.e. fast javascript response is
  # expected.
  #****************
  def no_move_click(yaml_data_key)
      no_move_click_raw(
        $yaml_data[yaml_data_key][0].to_sym,
        $yaml_data[yaml_data_key][1],
        $yaml_data[yaml_data_key][2]
      )
  end
  def no_move_click_raw(how, what, tag_name)
      e = @driver.find_element(how, what)
      @debug and print "In no_move_click, e: #{e}\n"
      e.tag_name.should == tag_name
      e.click.should be_nil
  end

  #****************
  # Takes a list of how, what, and tag_name, which work as usual.
  # For each such element, runs the "before" function, if any, then
  # click on the element, then run the "after" function, if any.
  #
  # It's called "no_move" because there's no expectation of a page
  # transition for these clicks, i.e. fast javascript response is
  # expected.
  #****************
  def multi_no_move_click( elements, before = false, after = false )
    elements.each do |how, what, tag_name|
      @debug and print "In multi_no_move_click: #{how}, #{what}, #{tag_name}\n"
      if before
        @debug and print "In multi_no_move_click, calling before\n"
        before.call
      end
      no_move_click( how, what, tag_name )
      if after
        @debug and print "In multi_no_move_click, calling after\n"
        after.call
      end
    end
  end

  #****************
  # Does what it says  :)
  #****************
  def close_current_window()
    @driver.close.should be_nil
    # Just in case
    @driver.switch_to.window(@driver.window_handles.last).should be_nil
  end

  #****************
  # A fake page refresh that works by going to the very first URL we
  # loaded, and then back to the current page.
  #
  # In other words, we totally fake this -_-
  #
  # Also, it doesn't work if @server_url is the current page
  # (although that's unlikely)
  #****************
  def refresh
    url=@driver.current_url
    @driver.navigate.to @server_url
    @driver.navigate.to url
    @driver.current_url.should == url
    return quiesce
  end

  #****************
  # Clicks on an element and expects that to cause a new window to
  # popup, which it then switches to.
  #****************
  def click_and_change_window(how, what, tag_name, resulting_url)
    e = @driver.find_element(how, what)
    3.times do 
      e.tag_name.should == tag_name
      e.click.should be_nil

      quiesce

      if @driver.window_handles.length > 1
        break
      end
    end

    # The actual window switching
    @driver.switch_to.window(@driver.window_handles.last).should be_nil

    check_url_match(resulting_url)
    return e
  end

  #****************
  # Just checks that the element has the given text
  #****************
  def check_element_text(how, what, text)
    e = @driver.find_element(how, what)
    e.text.should == text
  end

  #****************
  # Switches to an open alert, checks that it has the given text,
  # and clicks "yes" or similar.
  #****************
  def eat_alert(text)
    if @browser.to_sym == :chrome
      print "ALERT HANDLING IS BROKEN ON CHROME, so I'm pausing for you to click the alert.  Hit enter when ready to continue:  "
      File.open("/dev/tty", "r").gets
      quiesce
    else
      a = @driver.switch_to.alert
      a.text.should == text
      a.accept
      quiesce
    end
  end

  #****************
  # Basic debugging tool; prints information about the element.
  #****************
  def print_element_info(element)
    print "\n\n"
    print "== Element Info ==\n"
    print "tag name: #{element.tag_name}\n"
    print "value: #{element['value']}\n"
    print "text: #{element.text}\n"
    print "location: #{element.location}\n"
    print "\n\n"
  end

  #****************
  # Drops into a debugger
  #****************
  def wait_for_user()
    require 'ruby-debug'
    debugger
  end

  #****************
  # Checks that the current page title equals the given text
  #****************
  def check_page_title(text)
    @driver.title.should == text
  end

  #****************
  # Checks that the current page url matches the given text when
  # treated as a regex
  #****************
  def check_url_match(string)
    @driver.current_url.should =~ Regexp.new(string, Regexp::MULTILINE)
  end

  #****************
  # Checks that the current page *source* matches the given text
  # when treated as a regex.
  #
  # This is used for things like watching for javascript
  # "Loading..." messages to see when things are done
  #****************
  def check_page_source_match(string)
    @driver.page_source.should =~ Regexp.new(string, Regexp::MULTILINE)
  end

  #****************
  # Checks that the value of an attribute on an element is equal to
  # the given text
  #****************
  def check_attribute(how, what, attribute, string)
    e = @driver.find_element(how, what)
    e.attribute(attribute).should == string
  end

  #****************
  # Checks that the value of an attribute on an element matches
  # the given text treated as a regex
  #****************
  def check_attribute_match(how, what, attribute, string)
    e = @driver.find_element(how, what)
    if e.attribute(attribute) !~ Regexp.new(string, Regexp::MULTILINE) and @debug
      wait_for_user()
    end
    e.attribute(attribute).should =~ Regexp.new(string, Regexp::MULTILINE)
  end

  #****************
  # Tries to make sure that a page has completely finished loading
  # all javascripty bits by looking for text like "Loading..."
  #
  # Probably tied to tightly to the initial dev environment.
  #****************
  def quiesce()
    source1 = nil
    source2 = @driver.page_source

    i = 0
    while source1 != source2 or source2.match(/[^">]Loading...[^"]/) or source2.match(/[^">]Updating...[^"&]/)

      # Debugging check
      if i > 5 and @debug
        print "Still loading?  Really?\n"
        File.open("/tmp/source1", 'w') {|f| f.write(source1) }
        File.open("/tmp/source2", 'w') {|f| f.write(source2) }
        dump_page_source("/tmp/still-loading.html")
        wait_for_user
      end

      i += 1
      if i > 10
        break
      end
      sleep 1
      print "-"
      source1 = source2
      source2 = @driver.page_source
    end
    return source1 == source2
  end

  #****************
  # Gives an element a while (about 5 seconds) to show up on the
  # page, errors if it doesn't.
  #****************
  def wait_for_element(yaml_data_key)
    wait_for_element_raw($yaml_data[yaml_data_key][0], $yaml_data[yaml_data_key][1])
  end
  def wait_for_element_raw(how, what)
    e = nil
    5.times do |x|
      # note that find-element auto-waits
      e = @driver.find_element(how, what)
      if e.displayed?
        break
      end
      sleep 1
    end
    e.should be_displayed
    return e
  end

  #****************
  # Dumps the entire source of the current page, as seen by Selenium
  # so this includes the effects of javascript and so on, to the
  # given file.
  #****************
  def dump_page_source(file)
    File.open(file, 'w') {|f| f.write(@driver.page_source) }
  end

  #****************
  # Given an array of strings, check that all those bits of text are
  # present in the page source.
  #****************
  def multi_source_text_check(texts)
    texts.each do |text|
      page_text = @driver.page_source
      page_text.gsub!(/<[^>]*>/, '')
      page_text.gsub!(/\s+/, ' ')
      page_text.should include( text )
      print "."
    end
  end

  #****************
  # Runs manipulate_option over a list of lists of 5 elements,
  # corresponding to the arguments to manipulate_option ; see
  # manipulate_option  (obviously) for details.
  #****************
  def multi_manipulate_option(options)
    if options == nil
      return
    end
    options.each do |manip_type, *args|
      if manip_type != nil
        manipulate_option(manip_type.to_sym, *args )
        print "."
      end
    end
  end

  #****************
  # Configures an option in a dropdown selection element or multi
  # selection element.
  #
  # manip_type is :on for normal dropdown select, :multi_on, or
  # :multi_off; no :off, for that :on the element you want
  #
  # how and what how we find the overall selection element
  #
  # option_attribute option_attribute_value are how we find the
  # correct option itself.
  #
  #****************
  def manipulate_option(manip_type, how, what, option_attribute, option_attribute_value)
    select_element = @driver.find_element(how.to_sym, what)
    found=false
    select_element.find_elements(:tag_name, "option").each do |option|
      if( option.attribute(option_attribute) == option_attribute_value )
        found=option
        if( manip_type == :on and ! option.selected? )
          option.click
        end
        if( manip_type == :multi_on and ! option.selected? )
          option.click
        end
        if( manip_type == :multi_off and option.selected? )
          option.click
        end
        break
      end
    end
    found.attribute(option_attribute).should == option_attribute_value
    if( manip_type == :multi_off )
      found.should_not be_selected
    else
      found.should be_selected
    end
  end

  #****************
  # This script is given a set of elements that can all be
  # javascriptily dragged to each other's location, and makes them
  # appear in the order listed.  First argument is the axis (:x or
  # :y) to do the ordering.
  #
  # OK, we get called like this:
  #
  #    drag_to_order( :x, [
  #                  [ :name, "Channels[]" ],
  #                  [ :name, "Conditions[]" ],
  #                  [ :name, "Populations[]" ] ] )
  #
  # First we get the current relevant-dimension positions of all the
  # elements, and sort them, so we know where to put things.
  #
  # Then we move the first element to the negative of the first
  # position, if it isn't already there (where "there" is defined as
  # within 10 of the first position).
  #
  # Then we recurse on the rest of both lists.
  # 
  # If only one item, return true.
  #
  #****************
  def drag_to_order( dimension, items )
    positions = Array.new
    items.each_index do |n|
      item=@driver.find_element( items[n][0].to_sym, items[n][1] )
      positions[n] = item.location.send( dimension )
    end
    positions.sort!
    @debug and print "In drag_to_order: items: #{YAML.dump(items)}\n"
    @debug and print "In drag_to_order: positions: #{YAML.dump(positions)}\n"
    drag_to_order_internal( dimension, items, positions )

    # Then we re-pull the positions and check them
    last=0
    current=0
    items.each_index do |n|
      item=@driver.find_element( items[n][0].to_sym, items[n][1] )
      current = item.location.send( dimension )
      current.should satisfy { |current| current > last }
      last = current
    end
  end

  # No user servicable parts inside
  def drag_to_order_internal( dimension, items, positions )
    if items.length == 1
      return true
    end

    while true
      current=@driver.find_element( items[0][0].to_sym, items[0][1] )

      current_loc = current.location.send( dimension )
      jitter = 0
      if dimension == :x
        jitter = current.size.width
      else
        jitter = current.size.height
      end

      diff = positions[0] - current_loc

      @debug and print "In drag_to_order_internal: current: #{current}\n"
      @debug and print "In drag_to_order_internal: d0: #{positions[0]}\n"
      @debug and print "In drag_to_order_internal: current_loc: #{current_loc}\n"
      @debug and print "In drag_to_order_internal:diff : #{diff}\n"

      # Increase the absolute value of diff slightly, and keep the
      # sign
      fixed_diff = diff != 0 ? ((diff.abs + jitter - 1) * (diff/diff.abs)) : 0
      if diff.abs > jitter
        x = 0
        y = 0
        if dimension == :x
          x = [ fixed_diff, (diff * 1.2).to_i ].max
        end
        if dimension == :y
          y = [ fixed_diff, (diff * 1.2).to_i ].max
        end

        hover_and_move_slow( items[0][0].to_sym, items[0][1], x, y )
      else
        break
      end
    end

    drag_to_order_internal( dimension, items[1..-1], positions[1..-1] )
  end

  #****************
  # Moves the element by the amounts given, in small chunks, and
  # recover from problems if the element doesn't actually move the
  # way you expect.
  #****************
  def hover_and_move_slow(how, what, move_x, move_y)
    @debug and print "In hover_and_move_slow: #{how}, #{what}, #{move_x}, #{move_y}\n"
    distance = [ 40, ((move_x + move_y)/4).abs].max
    e=@driver.find_element(how, what)
    @driver.action.click_and_hold(e).perform

    x = e.location.x
    y = e.location.y

    goal_x = x + move_x
    goal_y = y + move_y

    while( (goal_x - x).abs > 5 or (goal_y - y).abs > 5 )
      diff_x = goal_x - x
      diff_y = goal_y - y

      while( diff_x.abs > distance )
        diff_x = diff_x / 2;
      end

      while( diff_y.abs > distance )
        diff_y = diff_y / 2;
      end

      @debug and print "In hover_and_move_slow: moving x #{diff_x} and y #{diff_y}, given current x #{x} and y #{y} with goals x #{goal_x} and y #{goal_y}\n"

      @driver.action.move_by(diff_x, diff_y).perform

      #@debug and sleep 2

      e=@driver.find_element(how, what)
      x = e.location.x
      y = e.location.y
    end

    @debug and print "In hover_and_move_slow: exited main loop, current x #{x} and y #{y} with goals x #{goal_x} and y #{goal_y}\n"

    @driver.action.release.perform
  end

  #****************
  # Set all of the options to unselected in a multiple select tag
  #****************
  def clear_multi_option_select(how, what)
    select_element=@driver.find_element(how, what)
    select_element.find_elements(:tag_name, "option").each do |option|
      if option.selected?
         option.toggle
      end
    end
  end

  #****************
  # Takes an array of how, what and a string, and makes sure that
  # each element's text is string equal to the given string
  #****************
  def multi_element_text_check( elements )
    wanted = Array.new
    found = Array.new
    elements.each do |element|
      print "."
      e = @driver.find_element(element[0].to_sym, element[1])
      wanted << [ element[1], element[2] ]
      found << [ element[1], e.text ]
    end

    found.should == wanted
  end

  #****************
  # Takes an array of how, what, attribute name, and attribute
  # value, and checks that each element's value for the given
  # attribute name is string equal to the given value
  #****************
  def multi_element_attr_check( elements )
    wanted = Array.new
    found = Array.new
    elements.each do |element|
      print "."
      e = @driver.find_element(element[0].to_sym, element[1])
      wanted << [ element[1], element[2], element[3] ]
      found  << [ element[1], element[2], e.attribute(element[2]) ]
    end

    found.should == wanted
  end

  #****************
  # Same as multi_element_attr_check but with regexes
  #****************
  def multi_element_attr_match( elements )
    elements.each do |element|
      print "."
      wait_for_element(element[0].to_sym, element[1])
      check_attribute_match(element[0].to_sym, element[1], element[2], element[3])
    end
  end

  #****************
  # Given an array ref, check that all those elements are present.
  #****************
  def multi_element_check( elements )
    elements.each do |element|
      wait_for_element(element[0].to_sym, element[1])
      print "."
    end
  end

  #****************
  # Enters text into a javascript-based editing element, rather than
  # a normal text field.  This is for dealing with situations where
  # javascript makes significant manipulations to the elements after
  # typing, so that references to the elements are lost and so on,
  # so this code goes back and re-finds the elements after typing to
  # test that the contents are correct.
  #
  # It's probably only of limited usefulness for most people.
  #
  # First argument is the element that initially needs clicking into
  # to do the editing (because sometimes finding that element is hard).
  #
  # Pairs are:
  #
  # Elem into which to type, relative to X's parent
  #
  # Re-finder for X after the typing, relative to X's parent
  #
  #****************
  def js_element_text_edit( startelem,
                           elemtype, elemloc,
                           pchildtype, pchildloc,
                           text )

    parent = startelem.find_element(:xpath, '..')

    startelem.click.should == nil

    input = parent.find_element(elemtype, elemloc)

    input.clear

    input.send_keys([ :backspace, :backspace, :backspace, :backspace,
                    :backspace, :backspace, :backspace, :backspace,
                    :backspace, :backspace, :backspace, :backspace,
                    :backspace, :backspace, :backspace, :backspace,
                    text, :enter ])

    # Give things time to update
    sleep 2
    quiesce

    pchild = parent.find_element(pchildtype, pchildloc)
    5.times do |x|
      if pchild.text == text
        break
      else
        sleep 1
      end
    end
    pchild.text.should == text
  end

end
