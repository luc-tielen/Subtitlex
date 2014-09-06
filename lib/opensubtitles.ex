defmodule Subtitlex.OpenSubtitles do
  alias Subtitlex.Subtitle
  import SweetXml
  use Pipe
  
  @moduledoc """
  Module containing the code to fetch subtitles from OpenSubtitles.org.
  """

  @base_url "http://www.opensubtitles.org"
  @tmp_dir "/tmp/"

  @doc """
  Tries to fetch a subtitle for a specific episode.
  """
  def fetch(episode_name, language \\ :english) 
      when episode_name |> is_binary 
      and language |> is_atom do

    pipe_matching {:ok, _},
    {:ok, {episode_name, language}}
      |> get_hash
      |> get_list_of_subs
      |> choose_best_srt
      |> download_subtitle
      |> unzip
      |> rename_file

    Subtitlex.Fetcher.notify_done(episode_name)
  end

  @doc false
  defp get_hash({:ok, {episode_name, language}}) do
    # The following line is bad code, has to be improved in next version of
    # cure..
    {:ok, server} = 
      Application.app_dir(:subtitlex) <> "/../c_src/program"
        |> Path.expand
        |> Cure.load

    server |> Cure.send_data(episode_name)

    receive do
      {:cure_data, "Error reading incoming data." = msg} -> 
        IO.puts msg
        Cure.stop server
        {:error, :incoming_data}
      {:cure_data, "Error opening file." = msg} -> 
        IO.puts msg
        Cure.stop server
        {:error, :opening_file}
      {:cure_data, <<hash_value::64>>} ->
        hash = Integer.to_string hash_value, 16
        IO.puts "Episode name: " <> format_name(episode_name) 
                                <> ", hash: " <> hash
        Cure.stop server
        {:ok, {hash, episode_name, language}}
      after 5000 -> 
        IO.puts "Timeout calculating hash."  
        Cure.stop server
        {:error, :timeout}
    end
  end

  @doc false
  defp get_list_of_subs({:ok, {hash, episode_name, language}}) do
    lang = case language do
      :english -> "eng"
      :dutch -> "dut"
      # TODO add more languages here later!
      _ -> "eng" 
    end

    url = @base_url <> "/en/search/sublanguageid-" <> lang <> "/moviehash-" 
                    <> hash 
                    <> "/simplexml"
    
    %HTTPoison.Response{body: subtitle_xml} = HTTPoison.get url

    #TODO improve this code later
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
    
    subs_found = length subtitle_urls

    if subs_found == 0 do
      episode = episode_name |> format_name 
      IO.puts "No subtitles found for " <> episode <> "."
      {:error, :no_subtitles_found}
    else
      subtitles = for i <- 0..(subs_found - 1) do
        sub_url = Enum.at(subtitle_urls, i)
        {sub_rating, ""} = Enum.at(subtitle_ratings, i) |> Float.parse
        Subtitle.new(sub_url, sub_rating)
      end

      {:ok, {subtitles, episode_name}}
    end
  end

  @doc false
  defp choose_best_srt({:ok, {[%Subtitle{} | _] = subtitles, episode_name}}) do
    sort_function = fn(%Subtitle{rating: rating1}, 
                      %Subtitle{rating: rating2}) ->
      rating1 > rating2
    end

    best_subtitle = 
      subtitles 
        |> Enum.sort(sort_function)
        |> List.first
    {:ok, {best_subtitle, episode_name}}
  end

  @doc false
  defp download_subtitle({:ok, {%Subtitle{link: link}, episode_name}}) do
    %HTTPoison.Response{body: zip_file} = HTTPoison.get link
    episode = episode_name |> format_name
    zip_location = @tmp_dir <> episode <> ".zip"
    File.write! zip_location, zip_file
    {:ok, {zip_location, episode_name}}
  end

  @doc false
  defp unzip({:ok, {zipped_subtitle_location, episode_name}}) do
    episode = episode_name |> format_name
    folder_name = @tmp_dir <> episode <> "/"
    
    System.cmd("unzip", ["-o", zipped_subtitle_location, "-d", folder_name])
    {ls_output, 0} = System.cmd("ls", [folder_name])    
    [subtitle] = 
      ls_output 
        |> String.split("\n")
        |> Enum.filter(fn(file) ->
          String.contains? file, ".srt"
        end)
    {:ok, {folder_name <> subtitle, episode_name}}
  end

  @doc false
  defp rename_file({:ok, {srt_file, episode_name}}) do
    new_subtitle_location =
      episode_name
        |> String.split(".")
        |> Enum.drop(-1)
        |> Enum.join(".")
        |> Kernel.<> ".srt"
    
    File.cp!(srt_file, new_subtitle_location)
    
    new_subtitle_name = 
      new_subtitle_location
        |> String.split("/")
        |> Enum.fetch! -1

    IO.puts "Downloaded " <> new_subtitle_name <> "."
  end

  @doc false
  defp format_name(episode_name) do
    episode_name |> String.split("/") |> Enum.fetch! -1
  end
end
