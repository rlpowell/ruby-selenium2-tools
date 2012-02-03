require 'rspec'

share_as :Translate do
  describe 'go to the google translate page via the main site' do
    it "should load the main page" do
      @driver.navigate.to @server_url
    end

    it 'should click on the More link' do
      no_move_click(:id, 'gbztms1', 'span')
    end

    it 'should click on the translate link and load the new page' do
      check_element_click(:id, "gb_51", "a", "^http://translate.google.com/.hl=en.tab=wT$"  )
      quiesce
    end
  end
end
