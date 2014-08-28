defmodule Subtitlex.Fetcher do
  use GenServer

  defmodule State do
    defstruct creator: nil, status: HashDict.new
  end

  def start_link(episodes, api \\ :opensubtitles, language \\ :english) 
      when episodes |> is_list 
      and api |> is_atom
      and language |> is_atom do
    GenServer.start_link(__MODULE__, 
                          [self, episodes, api, language], 
                          [name: __MODULE__])
  end

  def init([creator, episodes, api, language]) do
    status = 
      episodes 
        |> Enum.map(fn(episode) -> {episode, :busy} end) 
        |> Enum.into HashDict.new 

    Enum.map episodes, fn(episode) ->
      do_fetch(episode, api, language)
    end

    {:ok, %State{creator: creator, status: status}}
  end

  def stop do
    GenServer.cast(__MODULE__, :stop)
  end

  def notify_done(episode) when episode |> is_binary do
    GenServer.cast(__MODULE__, {:done, episode})
  end

  def handle_cast({:done, episode}, state) do
    new_status = state.status |> Dict.put episode, :finished
    new_state = %State{state | status: new_status}

    if finished?(new_status) do
      state.creator |> notify_finished
      {:stop, :normal, new_state} 
    else
      {:noreply, new_state}
    end
  end

  def handle_cast(:stop, state) do
    state.creator |> notify_stopped
    {:stop, :normal, state}
  end

  # Helper functions:

  defp do_fetch(episode, api, language) do
    {:ok, server} = Subtitlex.Supervisor.start_child
    server |> Subtitlex.Server.fetch(episode, api, language)
  end

  defp notify_stopped(pid) when pid |> is_pid do
    pid |> send :stopped
  end

  defp finished?(status) do
    [] == Enum.filter status, fn({_episode, ep_status}) -> 
      ep_status == :busy 
    end
  end

  defp notify_finished(pid) when pid |> is_pid do
    pid |> send :finished
  end
end
