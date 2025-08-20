defmodule Printer do

  def display_fireflies(print_frequency, num, clock_unit) do

    fireflies_pid_lists = []

    deadline_for_collecting_firefly_pids = System.monotonic_time(:millisecond) + clock_unit

    fireflies_pid_lists = collect_fireflies_pids(fireflies_pid_lists, num, deadline_for_collecting_firefly_pids)

    # IO.puts("Printer collected #{length(fireflies_pid_lists)} firefly PIDs")
    # IO.inspect(fireflies_pid_lists)
    keep_asking_and_listning(print_frequency, fireflies_pid_lists)

  end


  # only run once the start of application
  defp collect_fireflies_pids(fireflies_pid_lists, num, deadline) do
    now = System.monotonic_time(:millisecond)
    remaining_time = max(deadline - now, 0)

    if remaining_time == 0 or length(fireflies_pid_lists) == num do
      fireflies_pid_lists
    else
      receive do
        {:newly_created_firefly, new_firefly_id} ->
          updated_list = fireflies_pid_lists ++ [new_firefly_id]
          collect_fireflies_pids(updated_list, num, deadline)

      after
        remaining_time ->
          fireflies_pid_lists
      end
    end
  end



  defp keep_asking_and_listning(print_frequency, fireflies_pid_lists) do

    :timer.sleep(div(1000, print_frequency))
    IO.write(IO.ANSI.clear() <> IO.ANSI.home())

    # printing section
    ask_fireflies_state(fireflies_pid_lists)
    status_map = state_listner(print_frequency)
    # IO.inspect(status_map)
    line_state =
      for id <- 1..map_size(status_map) do
        case Map.get(status_map, id) do
          1 -> "B"
          _ -> " "
        end
      end

    IO.write(Enum.join(line_state))
    keep_asking_and_listning(print_frequency, fireflies_pid_lists)

  end

  # printer's support method
  defp ask_fireflies_state(fireflies_pid_lists) do
    for pid <- fireflies_pid_lists do
      send(pid, {:get_state})
    end
  end

  defp state_listner(p) do
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
