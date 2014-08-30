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
      {[lang: "nl"], episodes, _} ->
        {episodes, language: :dutch}
      {[lang: "nederlands"], episodes, _} ->
        {episodes, language: :dutch}

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
      - Dutch (nl)
      - MORE COMING SOON!
        
    Current supported databases:
      - Opensubtitles
      - MORE COMING SOON!
    """
  end
  defp handle({episodes, language: lang}) do
    # TODO implement language and other API's later!
    api = :opensubtitles 
    Subtitlex.Fetcher.start_link(episodes, api, lang)
    
    receive do
      :finished -> 
        IO.puts "Finished downloading subtitles."
      :stopped -> 
        :ok
    after 10000 ->
      IO.puts "Finished downloading subtitles."
    end
  end
end
