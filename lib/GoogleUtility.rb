module GoogleUtility
  def click_logo
    quiesce
    no_move_click(:id, 'hplogo', 'img')
    quiesce
  end
end
