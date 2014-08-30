defmodule Subtitlex.Mixfile do
  use Mix.Project

  def project do
    [app: :subtitlex,
     version: "0.0.1",
     elixir: "~> 0.15.1",
     description: description,
     deps: deps,
     package: package,
     escript: escript]
  end
  
  def application do
    [applications: [:logger, :cure, :httpoison],
    registered: [Subtitlex.Supervisor],
    mod: {Subtitlex, []}]
  end

  def description do
    """
    Subtitle-fetcher written in Elixir/C. Searches for subtitles on
    Opensubtitles.org based on video-hashes.
    """
  end

  defp deps do
    [{:cure, "~> 0.2.0"},
      {:pipe, "~> 0.0.1"},
      {:httpoison, "~> 0.4"},
      {:sweet_xml, "~> 0.1.0"}]
  end

  defp package do
    [files: ~w(lib priv c_src mix.exs README* readme* LICENSE* license*),
    contributors: ["Luc Tielen"],
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/Primordus/Subtitlex.git"}]
  end

  def escript do
    [main_module: Subtitlex,
     escript_embed_extra_apps: [:cure, 
                                :pipe, 
                                :httpoison, 
                                :sweet_xml]]
  end
end
