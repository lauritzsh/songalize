defmodule SongalizeTest do
  use ExUnit.Case
  doctest Songalize

  test "can parse title and artist" do
    # Truncated output from ffprobe v3.2.3
    song = """
  Metadata:
    artist          : B
    title           : C - D
    """
    |> Songalize.Song.parse_song_info

    expected = %{
      title: "C - D",
      artist: "B",
    }

    assert ^song = expected
  end

  test "will remove 'original mix' and 'original' from title" do
    song = %{title: "A (Original Mix)", album: "B", artist: "C"}
    |> Songalize.Song.remove_original_mix

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A (Original)", album: "B", artist: "C"}
    |> Songalize.Song.remove_original_mix

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "C"}
    |> Songalize.Song.remove_original_mix

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
    }

    assert ^song = expected
  end

  test "can parse radio edit" do
    song = %{title: "A (Radio Edit)", album: "B", artist: "C"}
    |> Songalize.Song.check_radio_edit

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      radio_edit: true,
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "C"}
    |> Songalize.Song.check_radio_edit

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      radio_edit: false,
    }

    assert ^song = expected
  end

  test "parses 'radio mix' as 'radio edit'" do
    song = %{title: "A (Radio Mix)", album: "B", artist: "C"}
    |> Songalize.Song.check_radio_edit

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      radio_edit: true,
    }

    assert ^song = expected
  end

  test "can parse features" do
    song = %{title: "A (feat. X)", album: "B", artist: "C"}
    |> Songalize.Song.check_feat

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      feat: "X",
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "C"}
    |> Songalize.Song.check_feat

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      feat: false,
    }

    assert ^song = expected
  end

  test "can parse artist features" do
    song = %{title: "A", album: "B", artist: "C feat. X"}
    |> Songalize.Song.check_artist_feat

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      feat: "X",
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "C & D featuring X"}
    |> Songalize.Song.check_artist_feat

    expected = %{
      title: "A",
      album: "B",
      artist: "C & D",
      feat: "X",
    }

    assert ^song = expected
  end

  test "can parse remix" do
    song = %{title: "A (X Remix)", album: "B", artist: "C"}
    |> Songalize.Song.check_remix

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      remix: "X",
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "C"}
    |> Songalize.Song.check_remix

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      remix: false,
    }

    assert ^expected = song
  end

  test "can parse radio edit and feat" do
    song = %{title: "A (Radio Edit) [feat. X]", album: "B", artist: "C"}
    |> Songalize.Song.clean_metadata

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      radio_edit: true,
      feat: "X",
      remix: false,
      with: false,
    }

    assert ^song = expected
  end

  test "will join artists with &" do
    song = %{title: "A", album: "B", artist: "C, D"}
    |> Songalize.Song.proper_join_artists

    expected = %{
      title: "A",
      album: "B",
      artist: "C & D",
    }

    assert ^song = expected
  end

  test "can parse feat and remix" do
    song = %{title: "A (X Remix) [feat. Y]", album: "B", artist: "C"}
    |> Songalize.Song.clean_metadata

    expected = %{
      title: "A",
      album: "B",
      artist: "C",
      radio_edit: false,
      feat: "Y",
      remix: "X",
      with: false,
    }

    assert ^song = expected
  end

  test "can normalize songs" do
    song = %{title: "A [radio edit]", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (Radio Edit)",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A [feat. X]", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (feat. X)",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A [ft. X]", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (feat. X)",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A [feat. X] (radio edit)", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (feat. X) [Radio Edit]",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A [Radio Edit] (X Remix)", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (X Remix) [Radio Edit]",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A (X remix)", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (X Remix)",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A (X Remix) [feat. Y]", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (feat. Y) [X Remix]",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "C & D feat. X"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (feat. X)",
      album: "B",
      artist: "C & D",
    }

    assert ^song = expected

    song = %{title: "A (feat. X & Y) [Remix]", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (feat. X & Y) [Remix]",
      album: "B",
      artist: "C",
    }

    assert ^song = expected

    song = %{title: "A (X Remix)", album: "B", artist: "C & D feat. Y"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (feat. Y) [X Remix]",
      album: "B",
      artist: "C & D",
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "CxD"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A",
      album: "B",
      artist: "CxD",
    }

    assert ^song = expected

    song = %{title: "A (with X)", album: "B", artist: "C"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A",
      album: "B",
      artist: "C & X",
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "C with X"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A",
      album: "B",
      artist: "C & X",
    }

    assert ^song = expected

    song = %{title: "A", album: "B", artist: "C with X Featuring Y"}
    |> Songalize.Song.normalize

    expected = %{
      title: "A (feat. Y)",
      album: "B",
      artist: "C & X",
    }

    assert ^song = expected
  end
end
