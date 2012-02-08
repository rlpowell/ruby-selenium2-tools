module GoogleUtility
  def click_irrelevant
    quiesce
    # Clicks the more link, twice
    no_move_click_raw(:id, 'gbztms1', 'span')
    quiesce
    no_move_click_raw(:id, 'gbztms1', 'span')
    quiesce
  end
end
