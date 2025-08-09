defmodule FirefliesFestival do
  use Application
  import ClockManager
  import Listener
  import Display
  import Config
  import StanderdConfig

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

    config = %Config{tf: 10, num: 50, ont: 0.5, oft: 1, dt: 1, pf: 30}
    sc = getStanderdConfig(config)


    # common shared mem for storing state of fireflies
    :ets.new(:fireflies_state, [:named_table, :public, :set])

    #  table to store firefly PIDs
    :ets.new(:fireflies_pids, [:named_table, :public, :set])

    for id <- 1..sc.num do
      :ets.insert(:fireflies_state, {id, 0})
    end

    max_random_time = config.tf * 2   #initial clock time in terms of ut [ 0 to 2*tick_freq ]

    # creating one process per firefly
    fireflies =
      for id <- 1..sc.num do
        pid = spawn_link(fn ->
          run_firefly(%Firefly{
            id: id,
            clock: :rand.uniform(max_random_time), # random float values
            state: 0,
            soft: sc.soft,
            sont: sc.sont,
            sdt: sc.sdt,
            num: sc.num,
            pid: self(),
            ut: sc.ut
          })
        end)
        {id, pid}  # returned for each itration to be stored in fireflies
      end

    # all pids for common mem access for broadcasting
    Enum.each(fireflies, fn {id, pid} ->
      :ets.insert(:fireflies_pids, {id, pid})
    end)

    IO.inspect(fireflies, limit: :infinity)
    spawn_link(fn -> show_fireflies(sc.pf) end)

  end


  defp run_firefly(%Firefly{} = f) do
    spawn_link(fn -> manage_clock(f) end)
    spawn_link(fn ->listen_to_fireflies(f) end)
  end


end
