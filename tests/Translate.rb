require 'rspec'

share_as :Translate do
  describe 'go to the google translate page via the main site' do
    it "should load the main page" do
      @driver.navigate.to @server_url
    end

    it 'should click on the More link' do
      no_move_click('translate_more_link')
    end

    it 'should click on the translate link and load the new page' do
      check_element_click('translate_click_translate')
      quiesce
    end
  end
end
