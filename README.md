# Subtitlex

**Work in progress..**

Subtitle-fetcher, written in Elixir and C. Concurrently fetches subtitles from Opensubtitles.org.

## Usage

subtitlex name(s)_of_episode(s) -l language
Example: subtitlex CoolestShowEver.mp4 bestSeriesEver.mkv -l en

## Requirements

- Erlang
- Elixir
- gcc, make (for compiling the C-source code)
- unzip (for unzipping zip-files from OpenSubtitles.org)

## Compiling Subtitlex

```
git clone git://github.com/Primordus/Subtitlex.git
mix do deps.get, deps.compile, cure.make, escript.build
```


