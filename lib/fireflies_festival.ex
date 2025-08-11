defmodule FirefliesFestival do
  use Application
  import ClockManager
  import Display
  import Config
  import StanderdConfig
  import SkipWaitTriggered
  import StateUpdater
  
  def start(_type, _args) do
    FirefliesFestival.main()
    Supervisor.start_link([], strategy: :one_for_one)
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

    config = %Config{tf: 10, num: 50, ont: 0.5, oft: 1, dt: 0.5, pf: 30}
    sc = getStanderdConfig(config)


    max_random_time = config.tf * 2   #initial clock time in terms of ut [ 0 to 2*tick_freq ]

    # creating one process per firefly
    fireflies =
      for id <- 1..sc.num do
        initial_clock = :rand.uniform(max_random_time) # random float values
        spawn_link(fn ->
          create_firefly(%Firefly{
            id: id,
            clock: initial_clock,
            state: 0,
            soft: sc.soft,
            sont: sc.sont,
            sdt: sc.sdt,
            pid: self(),
            ut: sc.ut
          })
        end)
      end

    IO.inspect(fireflies, limit: :infinity)
    spawn_link(fn -> display_fireflies(sc.pf) end)

  end


  defp create_firefly(%Firefly{} = f) do
    new = System.monotonic_time(:millisecond)
    run_firefly(f, new+f.ut)
  end


  # one process handling one firefly
  defp run_firefly(%Firefly{} = f, next_clock_time) do

    current_time = System.monotonic_time(:millisecond)
    remaining_time = max(next_clock_time - current_time, 0)

    receive do
      # from other fireflies
      {:on_state, from_id} ->
        if f.state == 0 and skip_wait_triggered?(f.id, from_id, f.num) do
          new_clock = f.clock + f.sdt
          f = %{f | clock: new_clock}
          f = update_state(f)
          run_firefly(f, next_clock_time)
        else
          run_firefly(f, next_clock_time)
        end


      # from printer
      {:get_state} ->
        for pid <- :pg.get_members(:printer_get_fireflies_state_topic) do
          if pid != self() do
            send(pid, {:on_state, f.id, f.state})
          end
        end
        run_firefly(f, next_clock_time)


      # after one tick time,
      after
        remaining_time ->
          f = tick_clock(f)        # clock++
          now = System.monotonic_time(:millisecond)
          run_firefly(f, f.ut+now) # for cycle time
    end

  end


end
