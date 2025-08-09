defmodule Listener do
  import SkipWaitTriggered
  import StateUpdater

  def listen_to_fireflies(%Firefly{} =f) do
    receive do
      {:on_state, from_id} ->
        if f.state == 0 and skip_wait_triggered?(f.id, from_id, f.num) do
          f = update_state(%{f | clock: min(f.clock + f.sdt, f.soft )})  # update state if needed
          listen_to_fireflies(f)
        else
          listen_to_fireflies(f)
        end
    end
  end
end
