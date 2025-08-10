defmodule Display do
  def show_fireflies(pf) do
    :timer.sleep(div(1000, pf))
    IO.write(IO.ANSI.clear() <> IO.ANSI.home())

    line_state =
      for id <- 1..:ets.info(:fireflies_state)[:size] do
        case :ets.lookup(:fireflies_state, id) do
          [{^id, 1}] -> "B"
          _ -> " "
        end
      end

    line_clock =
      for id <- 1..:ets.info(:fireflies_clock)[:size] do
        case :ets.lookup(:fireflies_clock, id) do
          [{^id, clock}] -> "#{clock}"
        end
      end

    IO.puts(Enum.join(line_clock))
    IO.puts(Enum.join(line_state))
    show_fireflies(pf)

  end
end
