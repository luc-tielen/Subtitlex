defmodule Subtitlex do
  use Application

  @moduledoc """
  Application module for Subtitlex. Also provides the entry point for the
  escript.
  """

  @doc """
  Starts the application.
  """
  def start(_type, _args) do
    HTTPoison.start
    Subtitlex.Supervisor.start_link
  end
  
  @doc """
  Invoked by the escript when executed.
  """
  def main(args) do
    args 
      |> parse_arguments
      |> handle
  end

  defp parse_arguments(args) do
    options = OptionParser.parse(args, 
                                switches: [help: :boolean, lang: :string],
                                aliases: [h: :help, l: :lang])
    case options do
      {[help: true], _, _} -> 
        :help
      {[], episodes, _} ->
        # If no language specified
        {episodes, language: :english}
      {[lang: "en"], episodes, _} -> 
        {episodes, language: :english}
      {[lang: "english"], episodes, _} -> 
        {episodes, language: :english}

      # TODO other languages..
      _ -> 
        :help
    end
  end

  defp handle(:help) do
    IO.puts """
    Usage: 'subtitlex name(s)_of_episode(s) -l language'
    Example: 'subtitlex coolest_show_ever.mp4 best_series_ever.mkv -l en'

    Current supported languages:
      - English (en) -> default setting.
      - MORE COMING SOON!
        
    Current supported databases:
      - Opensubtitles
      - MORE COMING SOON!
    """
  end
  defp handle({episodes, language: _lang}) do
    # TODO implement language and other API's later!
    Subtitlex.Fetcher.fetch episodes, :opensubtitles
    :timer.sleep 2000 # Otherwise processes get interrupted during fetching.
    # TODO remove later..
  end
end
