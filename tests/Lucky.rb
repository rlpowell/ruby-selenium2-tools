require 'rspec'

share_as :Lucky do
  describe 'run a feeling lucky search on Google' do
    it "should load the main page" do
      go_to('server_url')
    end

    it 'should take the text input' do
      check_element_send_keys('lucky_search_monkeys')
    end

    it 'should click elsewhere to close the javascripty bits' do
      click_irrelevant
    end

    it %q{should click on "I'm Feeling Lucky" and load the new page} do
      check_element_click('lucky_click_lucky')
      quiesce
    end
  end
end
