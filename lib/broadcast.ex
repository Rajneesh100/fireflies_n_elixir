defmodule Broadcast do
  # when switching to on state at clock =0 send to other processes
  def send_on_state_to_fireflies(id) do
    for pid <- :pg.get_members(:firefly_on_state_ping_topic) do
      if pid != self() do
        send(pid, {:on_state,  id})
      end
    end
  end

  def ask_fireflies_state do
    for pid <- :pg.get_members(:printer_get_fireflies_state_topic) do
      if pid != self() do
        send(pid, {:get_state})
      end
    end
  end
end
