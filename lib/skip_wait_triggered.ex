defmodule SkipWaitTriggered do
  # can be any logic currently if left neighbour has pinged then some dt wait time can be skipped
  def skip_wait_triggered?(id, from_id, num) do
    from_id == id - 1 or (id == 1 and from_id == num)
  end
end
