defmodule ClockManager do
  import StateUpdater

  def manage_clock(%Firefly{} =f) do
    :timer.sleep(trunc(f.ut))
    f = tick(f)          # clock++
    f = update_state(f)  # flip the state if needed
    manage_clock(f)      # keep running
  end

  # increment clock
  def tick(f), do: %{f | clock: f.clock + 1}
end
