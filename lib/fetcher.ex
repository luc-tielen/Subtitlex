defmodule Subtitlex.Fetcher do
  alias Subtitlex.OpenSubtitles
  require Logger

  def fetch(episode_name, api \\ :opensubtitles) 
      when episode_name |> is_binary
      and api |> is_atom do
    
    HTTPoison.start
    
    episode_location = abs_path(episode_name)
    
    case api do
      :opensubtitles -> OpenSubtitles.fetch(episode_location)
      _ -> raise ArgumentError, message: "API #{api} isn't implemented yet!"
    end
  end

  defp abs_path(episode_name) do
    Path.expand episode_name
  end
end
