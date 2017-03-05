# Songalize

Songalize helps you with your MP3 collection and their [ID3v2](https://en.wikipedia.org/wiki/ID3)
metadata by converting them to an opinionated, consistent format.

## Installation

The only dependency needed is [`id3v2`](http://id3v2.sourceforge.net/). Create a binary with `mix
escript.build`.

## Testing

Just run `mix test`.

## Usage

Just type `./songalize` and drop the MP3 files you want to update.

```
./songalize path/to/a.mp3 path/to/b.mp3
```

## Why?

I wanted my MP3 files to be in a more consistent format. Seeing featuring artists in the artist
column annoyed me as I think they should be part of the song title.

|   | Title       | Artist    |
|---|-------------|-----------|
| ✔ | A (feat. X) | B         |
| ✘ | A           | B feat. X |

The reason for Elixir is that I wanted to try it and the pattern matching seemed like a nice fit
here.
