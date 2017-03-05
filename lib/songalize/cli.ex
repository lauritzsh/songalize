defmodule Songalize.CLI do
  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [ help: :boolean],
                                     aliases:  [ h:    :help   ])

    case parse do
      { [ help: true ], _, _ } -> :help

      { _, files, _ } -> { files }

      _ -> :help
    end
  end

  def process(:help) do
    IO.puts """
    usage: tagger <file>
    """
    System.halt(0)
  end

  def process({ files }) do
    for path <- files, do: (
      path = String.trim(path)

      song = path
      |> Songalize.Song.get_song_info

      song
      |> Songalize.Song.normalize
      |> Songalize.Song.confirm(song)
      |> Songalize.Song.overwrite(path)
    )
  end
end
