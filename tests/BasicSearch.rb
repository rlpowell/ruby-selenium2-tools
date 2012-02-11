require 'rspec'

share_as :BasicSearch do
  describe 'run a basic search on Google' do
    it "should load the main page" do
      go_to('server_url')
    end

    it 'should take the text input' do
      $debug and dump_page_source("/tmp/goog1")
      check_element_send_keys('basic_search_search_monkeys')
      $debug and dump_page_source("/tmp/goog2")
    end

    it 'should click elsewhere to close the javascripty bits' do
      click_irrelevant
    end

    it 'should click on search and load the new page' do
      $debug and dump_page_source("/tmp/goog3")
      check_element_click('basic_search_click_search')
      quiesce
      $debug and dump_page_source("/tmp/goog4")
    end

    # This is, obviously, completely ridiculous to expect, but the
    # point is to show how the yaml_generate bits work; see the
    # readme for more details on how to handle changes here
    it 'should have the same item titles as last time' do
      multi_element_text_check( $yaml_data['basic_search_em_data'] )
    end
    it 'should have the same item urls as last time' do
      multi_element_text_check( $yaml_data['basic_search_cite_data'] )
    end
  end
end
