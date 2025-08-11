defmodule ClockManager do
  import StateUpdater

  def tick_clock(%Firefly{} =f) do
    f = %{f | clock: f.clock+1}
    update_state(f)      # flip the state if needed
  end

end
