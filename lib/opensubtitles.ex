defmodule Subtitlex.OpenSubtitles do
  alias Subtitlex.Subtitle

  @base_url "http://www.opensubtitles.org"
  @tmp_dir "/tmp/"

  def fetch(episode_name) when episode_name |> is_binary do
    episode_name
      |> get_hash
      |> get_list_of_subs
      |> choose_best_srt
      |> download_subtitle
      |> unzip
      |> rename_file(episode_name)
  end

  defp get_hash(episode_name) do
    {:ok, server} = Cure.load "./c_src/program"
    server |> Cure.send_data(episode_name)
    server |> Cure.stop

    receive do
      {:cure_data, "Error reading incoming data."} -> :error
      {:cure_data, "Error opening file."} -> :error
      {:cure_data, <<hash::64>>} -> Integer.to_string hash
      after 500 -> :timeout
    end
  end

  defp get_list_of_subs(hash) do
    # TODO make language etc not hardcoded! 
    # maybe use agent (register process) to store settings?
    url = @base_url <> "/en/search/moviehash-" <> hash <> "/simplexml"
    
    #TODO xml shizzle here

    subtitles = []
  end

  defp choose_best_srt([%Subtitle{} | _rest] = subtitles) do
    sort_function = fn(%Subtitle{rating: rating1}, 
                      %Subtitle{rating: rating2}) ->
      rating1 > rating2
    end

    subtitles 
      |> Enum.sort(sort_function)
      |> List.first
  end

  defp download_subtitle(%Subtitle{link: link}) do
    #TODO download + save to /tmp/name_of_zip + return that file location

  end

  defp unzip(zipped_subtitle_location) do
    System.cmd("unzip", [zipped_subtitle_location])
    @tmp_dir <> zipped_folder_name = zipped_subtitle_location
    folder_name = 
      zipped_folder_name 
        |> String.split "."
        |> Enum.drop -1
        |> Enum.join "."
    
    {ls_output, 0} = System.cmd("ls", [folder_name])    
    {subtitle, 0} = System.cmd("grep", ["\"*srt\"", ls_output])
    @tmp_dir <> subtitle
  end

  defp rename_file(srt_file, episode_name) do # episode_name is absolute path?
    new_subtitle_name =
      episode_name
        |> String.split "."
        |> Enum.drop -1
        |> Enum.join "."
        |> Kernel.<> ".srt"

    File.cp(srt_file, new_subtitle_name)
  end
end
