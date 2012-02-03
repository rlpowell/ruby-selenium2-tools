require 'rspec'

share_as :Lucky do
  describe 'run a feeling lucky search on Google' do
    it "should load the main page" do
      @driver.navigate.to @server_url
    end

    it 'should take the text input' do
      check_element_send_keys(:id, 'lst-ib', 'input', 'monkeys')
    end

    it 'should click elsewhere to close the javascripty bits' do
      click_logo
    end

    it %q{should click on "I'm Feeling Lucky" and load the new page} do
      check_element_click(:name, "btnI", "input", "^http://en.wikipedia.org/wiki/Monkey$"  )
      quiesce
    end
  end
end
