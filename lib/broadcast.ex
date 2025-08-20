defmodule Broadcast do
  # when switching to on state at clock =0 send state to other processes
  def broadcast_state_manager(num, clock_unit) do

    fireflies_pid_lists=[]
    deadline_for_collecting_firefly_pids = System.monotonic_time(:millisecond) + clock_unit

    fireflies_pid_lists = collect_fireflies_pids(fireflies_pid_lists, num, deadline_for_collecting_firefly_pids)

    # IO.puts("Broadcast collected #{length(fireflies_pid_lists)} firefly PIDs")

    listen_and_send_to_all(fireflies_pid_lists)

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
          # IO.inspect("rcvd new  #{inspect(new_firefly_id)}")
          updated_list = fireflies_pid_lists ++ [new_firefly_id]
          collect_fireflies_pids(updated_list, num, deadline)

      after
        remaining_time ->
          fireflies_pid_lists
      end
    end
  end

  def listen_and_send_to_all(fireflies_pid_lists) do
    receive do
      {:on_state, self_pid, self_index} ->
        for pid <- fireflies_pid_lists do
          if pid != self_pid do
            send(pid, {:on_state,  self_index})
          end
        end
        listen_and_send_to_all(fireflies_pid_lists)

    end

  end

end
