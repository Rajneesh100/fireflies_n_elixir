defmodule Broadcast do
  # when switching to on state at clock =0 send to other processes
  def broadcast(id) do
    :timer.sleep(1)  # 1ms, to avoid racing condition on updating clock when some pings comes in and normal incremnet is also going on
    :ets.tab2list(:fireflies_pids)  # ping to all fireflies
    |> Enum.each(fn {_firefly_id, pid} ->
      if pid != self() do
         send(pid, {:on_state, id})
      end
    end)
  end
end
