defmodule StateUpdater do
  import Broadcast

  # 0 -> 1 using runtime polymorphism for state change
  def update_state(%Firefly{state: 0, clock: c, soft: soft} = f) when c >= soft do
    broadcast(f.id)
    :ets.insert(:fireflies_state, {f.id, 1})
    %{f | state: 1, clock: 0}
  end

  #  1 -> 0
  def update_state(%Firefly{state: 1, clock: c, sont: sont} = f) when c >= sont do
    :ets.insert(:fireflies_state, {f.id, 0})
    %{f | state: 0, clock: 0}
  end

  # when no switch required
  def update_state(f) do
    f
  end
end
