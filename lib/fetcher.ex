defmodule Subtitlex.Fetcher do
  alias Subtitlex.OpenSubtitles

  def fetch(episode_name, api) when episode_name |> is_binary
                                and api |> is_atom do
    case api do
      :opensubtitles -> OpenSubtitles.fetch(episode_name)
      _ -> raise ArgumentError, message: "API #{api} isn't implemented yet!"
    end
  end
end
