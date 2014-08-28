defmodule Subtitlex.OpenSubtitles do
  alias Subtitlex.Subtitle
  import SweetXml
  require Logger
  use Pipe
  
  @base_url "http://www.opensubtitles.org"
  @tmp_dir "/tmp/"

  def fetch(episode_name) when episode_name |> is_binary do
    pipe_matching {:ok, _, _},
    {:ok, episode_name}
      |> get_hash
      |> get_list_of_subs
      |> choose_best_srt
      |> download_subtitle
      |> unzip
      |> rename_file
  end

  defp get_hash({:ok, episode_name}) do
    {:ok, server} = Cure.load "./c_src/program"
    server |> Cure.send_data(episode_name)
    #TODO change to Cure.stop after new Cure version!

    receive do
      {:cure_data, "Error reading incoming data." = msg} -> 
        Logger.error msg
        server |> Cure.Supervisor.terminate_child
        {:error, :incoming_data}
      {:cure_data, "Error opening file." = msg} -> 
        Logger.error msg
        server |> Cure.Supervisor.terminate_child
        {:error, :opening_file}
      {:cure_data, <<hash_value::64>>} ->
        hash = Integer.to_string hash_value, 16
        Logger.debug "Hash: " <> hash
        server |> Cure.Supervisor.terminate_child
        {:ok, hash, episode_name}
      after 1000 -> 
        Logger.error "Timeout calculating hash."  
        server |> Cure.Supervisor.terminate_child
        {:error, :timeout}
    end
  end

  defp get_list_of_subs({:ok, hash, episode_name}) do
    # TODO make language etc not hardcoded! 
    # maybe use agent (register process) to store settings?
    url = @base_url <> "/en/search/sublanguageid-eng/moviehash-" 
                    <> hash 
                    <> "/simplexml"
    
    %HTTPoison.Response{body: subtitle_xml} = HTTPoison.get url

    #TODO improve this code later, add language checking too.. 
    subtitle_urls = 
      subtitle_xml 
        |> xpath(~x"//download/text()"l)
        |> Enum.map(fn(url) ->
          url |> String.Chars.to_string |> String.strip ?\n
        end)
    subtitle_ratings =
      subtitle_xml
        |> xpath(~x"//subrating/text()"l)
        |> Enum.map(fn(xml) ->
          xml |> String.Chars.to_string
        end)
    
    subtitles = for i <- 0..(length(subtitle_urls) - 1) do
      sub_url = Enum.at(subtitle_urls, i)
      {sub_rating, ""} = Enum.at(subtitle_ratings, i) |> Float.parse
      Subtitle.new(sub_url, sub_rating)
    end

    {:ok, subtitles, episode_name}
  end

  defp choose_best_srt({:ok, [], episode_name}) do
    episode = episode_name |> format_name 
    Logger.debug "No subtitles found for " <> episode <> "."
    {:error, :no_subtitles_found}
  end
  defp choose_best_srt({:ok, [%Subtitle{} | _] = subtitles, episode_name}) do
    sort_function = fn(%Subtitle{rating: rating1}, 
                      %Subtitle{rating: rating2}) ->
      rating1 > rating2
    end

    best_subtitle = 
      subtitles 
        |> Enum.sort(sort_function)
        |> List.first
    {:ok, best_subtitle, episode_name}
  end

  defp download_subtitle({:ok, %Subtitle{link: link}, episode_name}) do
    %HTTPoison.Response{body: zip_file} = HTTPoison.get link
    episode = episode_name |> format_name
    zip_location = @tmp_dir <> episode <> ".zip"
    File.write! zip_location, zip_file
    {:ok, zip_location, episode_name}
  end

  defp unzip({:ok, zipped_subtitle_location, episode_name}) do
    episode = episode_name |> format_name
    folder_name = @tmp_dir <> episode <> "/"
    
    System.cmd("unzip", [zipped_subtitle_location, "-d", folder_name])
    {ls_output, 0} = System.cmd("ls", [folder_name])    
    [subtitle] = 
      ls_output 
        |> String.split 
        |> Enum.filter(fn(file) ->
          String.contains? file, ".srt"
        end)
    {:ok, folder_name <> subtitle, episode_name}
  end

  defp rename_file({:ok, srt_file, episode_name}) do
    new_subtitle_name =
      episode_name
        |> String.split(".")
        |> Enum.drop(-1)
        |> Enum.join(".")
        |> Kernel.<> ".srt"

    File.cp!(srt_file, new_subtitle_name)
    Logger.debug "Downloaded " <> new_subtitle_name <> "."
  end

  defp format_name(episode_name) do
    episode_name |> String.split("/") |> Enum.fetch! -1
  end
end
