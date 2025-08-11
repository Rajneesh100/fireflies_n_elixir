defmodule Display do
  import Broadcast

  def display_fireflies(pf) do
    :pg.join(:printer_recieve_fireflies_state_topic, self())  # listen for states
    fetch_and_print(pf)
  end



  def fetch_and_print(pf) do

    :timer.sleep(div(1000, pf))
    IO.write(IO.ANSI.clear() <> IO.ANSI.home())

    ask_fireflies_state()
    status_map = printer_listner(pf)
    # IO.inspect(status_map)
    line_state =
      for id <- 1..map_size(status_map) do
        case Map.get(status_map, id) do
          1 -> "B"
          _ -> " "
        end
      end

    IO.write(Enum.join(line_state))
    fetch_and_print(pf)

  end



  def printer_listner(p) do
    deadline = System.monotonic_time(:millisecond) + div(1000, p)
    default_status = %{}
  collect_states(default_status, deadline)

  end

  defp collect_states(states, deadline) do
    now = System.monotonic_time(:millisecond)
    remaining_time = max(deadline - now, 0)

    if remaining_time == 0 do
      states
    else
      receive do
        # from fireflies
        {:get_state, firefly_id, state} ->
          # IO.puts("got value")
          # IO.inspect(firefly_id)
          # IO.inspect(state)
          updated_states = Map.put(states, firefly_id, state)
          collect_states(updated_states, deadline)


      # deadline for each cycle
      after
        remaining_time ->
          states
      end
    end
  end
end
