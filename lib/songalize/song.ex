defmodule Songalize.Song do
  def get_song_info(path) do
    {output, 0} = System.cmd("ffprobe", [path], stderr_to_stdout: true)

    parse_song_info(output)
  end

  def parse_song_info(song) do
    [_match, title] = Regex.run(~r/title\s+: (.+)/, song)
    [_match, artist] = Regex.run(~r/artist\s+: (.+)/, song)
    # [_match, album] = Regex.run(~r/album\s+: (.+)/, song)

    %{title: title, artist: artist}# , album: album}
  end

  def remove_original_mix(metadata) do
    pattern = ~r/(?:\(|\[)original(?: mix)?(?:\)|\])/i

    case Regex.run(pattern, metadata.title) do
      nil -> metadata

      _ ->
        metadata
        |> Map.update!(:title, fn(t) ->
          pattern
          |> Regex.replace(t, "")
          |> String.trim
        end)
    end
  end

  def check_radio_edit(metadata) do
    pattern = ~r/(\(|\[)radio (?:edit|mix)(\)|\])/i

    case Regex.run(pattern, metadata.title) do
      nil ->
        metadata
        |> Map.put(:radio_edit, false)

      _ ->
        metadata
        |> Map.put(:radio_edit, true)
        |> Map.update!(:title, fn(t) ->
          pattern
          |> Regex.replace(t, "")
          |> String.trim
        end)
    end
  end

  def check_feat(metadata) do
    pattern = ~r/(?:\(|\[)f(?:ea)?t\. (.+?)(?:\)|\])/i

    case Regex.run(pattern, metadata.title) do
      [_match, feat] ->
        metadata
        |> Map.put(:feat, feat)
        |> Map.update!(:title, fn(t) ->
          pattern
          |> Regex.replace(t, "")
          |> String.trim
        end)

      nil ->
        metadata
        |> Map.put_new(:feat, false)
    end
  end

  def check_with(metadata) do
    pattern = ~r/(?:\(|\[)with (.+?)(?:\)|\])/i

    case Regex.run(pattern, metadata.title) do
      [_match, feat] ->
        metadata
        |> Map.put(:with, feat)
        |> Map.update!(:title, fn(t) ->
          pattern
          |> Regex.replace(t, "")
          |> String.trim
        end)

      nil ->
        metadata
        |> Map.put_new(:with, false)
    end
  end

  def check_artist_feat(metadata) do
    pattern = ~r/f(?:ea)?t(?:uring)?\.? (.+)/i

    case Regex.run(pattern, metadata.artist) do
      nil -> metadata

      [_match, feat] ->
        metadata
        |> Map.put(:feat, feat)
        |> Map.update!(:artist, fn(a) ->
          pattern
          |> Regex.replace(a, "")
          |> String.trim
        end)
    end
  end

  def proper_join_artists(metadata) do
    metadata
    |> Map.update!(:artist, fn(a) ->
      pattern = ~r/\s*(,| x )\s*/

      Regex.split(pattern, a)
      |> Enum.join(" x ")
    end)
  end

  def check_remix(metadata) do
    pattern = ~r/(?:\(|\[)remix(?:\)|\])|(?:\(|\[)(.+?) remix(?:\)|\])/i

    case Regex.run(pattern, metadata.title) do
      [_match, remix] ->
        metadata
        |> Map.put(:remix, remix)
        |> Map.update!(:title, fn(t) ->
          pattern
          |> Regex.replace(t, "")
          |> String.trim
        end)

      [_remix] ->
        metadata
        |> Map.put(:remix, "artist_remix")
        |> Map.update!(:title, fn(t) ->
          pattern
          |> Regex.replace(t, "")
          |> String.trim
        end)

      nil ->
        metadata
        |> Map.put(:remix, false)
    end
  end

  def clean_metadata(metadata) do
    metadata
    |> remove_original_mix
    |> check_radio_edit
    |> check_artist_feat
    |> proper_join_artists
    |> check_feat
    |> check_with
    |> check_remix
  end

  def normalize(metadata) do
    cleaned_metadata = clean_metadata(metadata)

    title = case cleaned_metadata do
      %{title: title, remix: false, feat: false, radio_edit: false} -> title

      %{title: title, remix: false, feat: false, radio_edit: true} ->
        "#{title} (Radio Edit)"

      %{title: title, remix: false, feat: feat, radio_edit: true} ->
        "#{title} (feat. #{feat}) [Radio Edit]"

      %{title: title, remix: false, feat: feat, radio_edit: false} ->
        "#{title} (feat. #{feat})"

      %{title: title, remix: "artist_remix", feat: false, radio_edit: true} ->
        "#{title} (Remix) [Radio Edit]"

      %{title: title, remix: "artist_remix", feat: false, radio_edit: false} ->
        "#{title} (Remix)"

      %{title: title, remix: remix, feat: false, radio_edit: true} ->
        "#{title} (#{remix} Remix) [Radio Edit]"

      %{title: title, remix: remix, feat: false, radio_edit: false} ->
        "#{title} (#{remix} Remix)"

      %{title: title, remix: "artist_remix", feat: feat, radio_edit: _} ->
        "#{title} (feat. #{feat}) [Remix]"

      %{title: title, remix: remix, feat: feat, radio_edit: _} ->
        "#{title} (feat. #{feat}) [#{remix} Remix]"
    end

    # album = case cleaned_metadata do
    #   %{album: album} -> album
    # end

    artist = case cleaned_metadata do
      %{artist: artist, with: false} -> artist

      %{artist: artist, with: with} -> "#{artist} x #{with}"
    end

    metadata
    |> Map.put(:title, title)
  # |> Map.put(:album, album)
    |> Map.put(:artist, artist)
  end

  def confirm(new, old) do
    if new == old do
      :no
    else
      IO.puts """
      \nOverwriting:
        Artist: #{old.artist}
          with: #{new.artist}

        Title: #{old.title}
         with: #{new.title}
      """

      case IO.gets "Confirm? [Yn] " do
        "n\n" -> :no
        _ -> {:yes, new}
      end
    end
  end

  def overwrite(:no, _path) do
    IO.puts "Skipping"
  end

  def overwrite({:yes, metadata}, path) do
    %{
      artist: artist,
    # album: album,
      title: title
    } = metadata
    {_output, 0} = System.cmd("id3v2", [path, "--song", title])
    # {_output, 0} = System.cmd("id3v2", [path, "--album", album])
    {_output, 0} = System.cmd("id3v2", [path, "--artist", artist])
  end
end
