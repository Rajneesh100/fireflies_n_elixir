defmodule StateUpdater do
  import Broadcast

  def update_state(%Firefly{} = f) do
    cond do
      # 0 -> 1
      f.state == 0 and f.clock >= f.soft ->
        send_on_state_to_fireflies(f.id)
        %{f | clock: 0, state: 1}

      #  1 -> 0
      f.state == 1 and f.clock >= f.sont ->
        %{f | clock: 0, state: 0}

      # no switch required
      true ->
        f
    end
  end
end
