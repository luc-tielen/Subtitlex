defmodule Subtitlex do
  use Application
  
  def start(_type, _args) do
    args = parse_arguments
    for i <- args, do: IO.puts i

    if Keyword.get(args, :show_help) do
      show_help
    else
      # de rest
      episodes = Keyword.get_values(args, :episode)
      language = Keyword.get(args, :language, :english)

      # TODO start supervisor! start executor!
      Subtitlex.Supervisor.start_link
      
      #TODO deze code moet ergens anders komen staan??
      #episodes |> length |> Executor.initialize
      #for episode <- episodes do
      #  %Executor.Task.new(module: Subtitlex.Fetcher, 
      #                      function: fetch, 
      #                     args: [episode, language]) 
      #   |> Executor.add_task
      #end
    end
  end

  defp parse_arguments do
    System.argv |> parse_arguments
  end

  defp parse_arguments([]), do: show_help
  defp parse_arguments(args), do: parse_arguments(args, [])
  defp parse_arguments([], acc), do: acc
  defp parse_arguments(["-h" | _rest], _acc), do: [show_help: true]
  defp parse_arguments(["--help" | _rest], _acc), do: [show_help: true]
  defp parse_arguments(["-l", language | rest], acc) do
    lang = case language do
      "english" -> :english
      "en" -> :english
      #TODO other languages!
      _ -> raise ArgumentError, 
                  message: "Language '#{language}' isn't supported yet!"
    end

    parse_arguments(rest, [{:language, lang} | acc])
  end
  defp parse_arguments([episode | rest], acc) do
    parse_arguments(rest, [{:episode, episode} | acc])
  end

  defp show_help do
    IO.puts """
    Usage: 'subtitlex name(s)_of_episode(s) -l language
    Example: 'subtitlex coolest_show_ever.mp4 best_series_ever.mkv -l en'

    Current supported languages:
      - English (en) -> default setting.
      - MORE COMING SOON!
        
    Current supported databases:
      - Opensubtitles
      - MORE COMING SOON!
    """
  end
end
