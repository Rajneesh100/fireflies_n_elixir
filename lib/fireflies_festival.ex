defmodule FirefliesFestival do
  use Application
  import ClockManager
  import Printer
  import Config
  import StanderdConfig
  import SkipWaitTriggered
  import StateUpdater
  import Broadcast

  def start(_type, _args) do
    FirefliesFestival.main() # run infinitly
    {:ok, self()}
  end




  def getStanderdConfig(%Config{} = config) do
    # unit time in ms for one clock tick 1000/freq
    ut = truncate (1000 / config.tf)
    %StanderdConfig{
      ut: ut,
      num: config.num,
      sont: truncate(config.ont*1000 / ut),
      soft: truncate(config.oft*1000 / ut),
      sdt: truncate(config.dt*1000 / ut),
      pf: config.pf
    }
  end



  defp truncate(x), do: Float.ceil(x) |> trunc()



  def main do

    #start the printer & broadcaster process it will store all the pids of firefly insted of using pub sub and it will send pings to all of them

    config = %Config{tf: 10, num: 50, ont: 0.5, oft: 2, dt: 2, pf: 30}
    sc = getStanderdConfig(config)

    # each fly will have these two thing to communicate with outer world
    printer_id = spawn_link(fn -> display_fireflies(sc.pf, sc.num , sc.ut) end)
    broadcaster_id = spawn_link(fn -> broadcast_state_manager(sc.num, sc.ut) end)



    max_random_time = config.tf * 2   #initial clock time in terms of ut [ 0 to 2*tick_freq ut ]

    # one process per firefly
    for id <- 1..sc.num do
      initial_clock = :rand.uniform(max_random_time)

      new_firefly_id = spawn_link(fn ->
        create_firefly(%Firefly{
          id: id,
          clock: initial_clock,
          state: 0,
          soft: sc.soft,
          sont: sc.sont,
          sdt: sc.sdt,
          pid: self(),
          ut: sc.ut,
          printer_id: printer_id,
          broadcaster_id: broadcaster_id
        })
      end)
      # IO.puts("neww firefly #{id} with PID #{inspect(new_firefly_id)}")
      # send it to broadcaster and printer so that they can maintain a list of fireflies & can ping all fireflies and but firefly remains isolated from each other
      send(printer_id, {:newly_created_firefly, new_firefly_id})
      send(broadcaster_id, {:newly_created_firefly, new_firefly_id})
    end




  end


  defp create_firefly(%Firefly{} = f) do

    new = System.monotonic_time(:millisecond)
    run_firefly(f, new+f.ut)
  end


  # one process handling one firefly
  defp run_firefly(%Firefly{} = f, next_clock_time) do
    current_time = System.monotonic_time(:millisecond)
    remaining_time = max(next_clock_time - current_time, 0)


    # IO.inspect(f)
    receive do

      # self message
      {:update_clock} ->
        f = tick_clock(f)
        now = System.monotonic_time(:millisecond)
        run_firefly(f, next_clock_time)


      # from broadcaster from other flies
      {:on_state, from_id} ->
        if f.state == 0 and skip_wait_triggered?(f.id, from_id, f.num) do
          new_clock = f.clock + f.sdt
          f = %{f | clock: new_clock}
          f = update_state(f)
          run_firefly(f, next_clock_time)
        else
          run_firefly(f, next_clock_time) # xhange tim
        end


      # clock update after one tick time,
      after
        remaining_time ->
          send(self(), {:update_clock})
          now = System.monotonic_time(:millisecond)
          run_firefly(f, now+f.ut)
    end

  end

  # defp shuffle(list , id ) do

  #   if id == enum,count(list)
  #   list
  #   updated_list = list
  #     rvr = Enum.count(updated_list) - id +1;
  #     new_idx  = trunc(:rand.uniform(rvr)),
  #     # list = {list | }
  #   updated_list = swap(updated_list, rvr, new_idx)
  #   shuffle(list, id+1)
  # end



end
