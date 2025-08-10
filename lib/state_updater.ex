defmodule StateUpdater do
  import Broadcast

  def update_state(%Firefly{} = f) do
    [{_, current_state}] = :ets.lookup(:fireflies_state, f.id)
    [{_, current_clock}] = :ets.lookup(:fireflies_clock, f.id)

    cond do
      # 0 -> 1 
      current_state == 0 and current_clock >= f.soft ->
        broadcast(f.id)
        :ets.insert(:fireflies_state, {f.id, 1})  # updating state & clock
        :ets.insert(:fireflies_clock, {f.id, 0})

      #  1 -> 0
      current_state == 1 and current_clock >= f.sont ->
        :ets.insert(:fireflies_state, {f.id, 0})  # updating state & clock
        :ets.insert(:fireflies_clock, {f.id, 0})

      # when no switch required
      true ->
        :ok
    end
  end
end
