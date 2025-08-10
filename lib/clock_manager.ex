defmodule ClockManager do
  import StateUpdater

  def manage_clock(%Firefly{} =f) do
    :timer.sleep(trunc(f.ut))
    [{_, current_clock}] = :ets.lookup(:fireflies_clock, f.id)
    new_clock = current_clock + 1
    :ets.insert(:fireflies_clock, {f.id, new_clock})
    update_state(f)      # flip the state if needed
    manage_clock(f)      # keep running
  end

end
