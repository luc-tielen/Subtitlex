defmodule Subtitlex.Server do
  use GenServer
  alias Subtitlex.OpenSubtitles

  @moduledoc """
  GenServer-process that is responsible for fetching a subtitle for an episode.
  """

  @doc """
  Instructs the server to fetch a subtitle for a specific language using a
  certain API.
  """
  def fetch(server, episode_name, api \\ :opensubtitles, language \\ :english) 
      when server |> is_pid
      and episode_name |> is_binary
      and api |> is_atom 
      and language |> is_atom do
    episode_location = abs_path(episode_name)
    server |> GenServer.cast({:fetch, episode_location, api, language})
  end

  @doc """
  Starts a Server-process.
  """
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  @doc false
  def init([]) do
    state = nil
    {:ok, state}
  end

  @doc """
  Stops the server process.
  """
  def stop(server) when server |> is_pid do
    server |> GenServer.cast(:stop)
  end

  @doc false
  def handle_cast({:fetch, episode, :opensubtitles, language}, state) do
    OpenSubtitles.fetch(episode, language)
    {:noreply, state}
  end
  def handle_cast({:fetch, _episode, api, _language}, state) do
    IO.puts "API for #{api} isn't implemented yet!"
    {:noreply, state}
  end
  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  @doc false
  defp abs_path(episode_name) do
    Path.expand episode_name
  end
end
