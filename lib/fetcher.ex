defmodule Subtitlex.Fetcher do
  require Logger

  def fetch([], _api) do
    :ok
  end
  def fetch([episode | rest] = _episodes, api \\ :opensubtitles) 
      when episode |> is_binary
      and api |> is_atom do
    do_fetch(episode, api)
    fetch(rest, api)
  end

  defp do_fetch(episode, api) do
    {:ok, server} = Subtitlex.Supervisor.start_child
    server |> Subtitlex.Server.fetch(episode, api)
  end
end
