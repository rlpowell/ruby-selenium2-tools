require 'rspec'

share_as :Setup do
  describe 'set up google' do
    it "should load the remote driver" do
      # FIXME: Maybe increase this timeout
      @driver.manage.timeouts.implicit_wait = 5 # seconds
      @driver.class.name.should == "Selenium::WebDriver::Driver"
    end

    it "should load the setup page" do
      @driver.navigate.to "http://www.google.com/preferences?hl=en"
    end

    it "should change to no instant predictions" do
      # There seem to actually be two versions of this floating out
      # there right now 0.o (31 Jan 2012), so we test for which to
      # do
      begin
        no_move_click(:id, 'psyDrag', 'div')
      rescue
        no_move_click(:id, ':2.label', 'div')
      end
    end

    it "should save the new setting" do
      check_element_click(:xpath, "//div[text()='Save']", "div", "^#{@server_url}/$"  )
    end
  end
end
