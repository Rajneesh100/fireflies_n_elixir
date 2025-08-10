defmodule Listener do
  import SkipWaitTriggered
  import StateUpdater

  def listen_to_fireflies(%Firefly{} =f) do
    receive do
      {:on_state, from_id} ->
        [{_, current_state}] = :ets.lookup(:fireflies_state, f.id)
        if current_state == 0 and skip_wait_triggered?(f.id, from_id, f.num) do

          # IO.inspect("recieved #{from_id} and self:#{f.id}")
          [{_, current_clock}] = :ets.lookup(:fireflies_clock, f.id)
          new_clock = min(current_clock + f.sdt, f.soft)
          :ets.insert(:fireflies_clock, {f.id, new_clock})
          update_state(f)  # check if state needs updating
          listen_to_fireflies(f)

        end
        listen_to_fireflies(f)
    end
  end
end
