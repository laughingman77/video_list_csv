# video_list_csv

Recursively create a CSV with details of all movie and TV media in a directory. Useful for cataloguing archive disks.

The result CVS also contains summary data of `Disk Space used` and `Disk Space free`. This allows you to see free disk space after your media centre's metadata is taken into account.

# Install

## Requirements

* jq
* ffmpeg

```bash
sudo apt install jq ffmpeg
```
    

## .env

Copy `example.env` to `.env`

```bash
cp example.env .env
```

# Directory and Filenames

The script assume directory and filenaming structure for [Jellyfin][jellyfin].

This format is broadly compatible with [kodi][kodi] and [plex][plex]. Howver the main differences will be with:

* different movie versions, where [jellyfin][jellyfin] uses the ` - ` to separate version text from filename text.
* `tmdbid` and `imdbid` codes.

## Movies

```text
Movie.Name.Year..General.text.ext
Movie Name (Year) General text.ext
Movie Name (Year) [tmdbid-...] General text.ext
├── Movie Name
│   ├── Movie Name- [variant text].ext
├── Movie Name (year)
│   ├── Movie Name (year) - version 1 text.ext
│   ├── Movie Name (year) - version 2 text.ext
├── Movie Name (year) [tmdbid-...]
│   ├── Movie Name (year) [tmdbid-...] - version 1 text.ext
│   ├── Movie Name (year) [tmdbid-...] - version 2 text.ext
├── Movie Name (year) [imdbid-...]
│   ├── Movie Name (year) [imdbid-...] - version 1 text.ext
│   ├── Movie Name (year) [imdbid-...] - version 2 text.ext
```

## TV Shows

**Note:** The capitalisation of TV shows within a season must be the same as the containing TV show ditectory.

```text
├── TV Show
│   ├── Season 1
│   │  ├── TV Show S01E01 general text.ext
│   │  ├── ...
├── TV Show (year)
│   ├── Season 1
│   │  ├── TV Show (year) S01E01 general text.ext
│   │  ├── ...
├── TV Show (year) [tmdbid-...]
│   ├── Season 1
│   │  ├── TV Show (year) [tmdbid-...] S01E01 general text.ext
│   │  ├── ...
```

# Usage

1. Make a copy of the spreadsheet
1. Duplicate the `Archive Template` sheet for your archive disk
1. Run the script as below.
    1. `movie_list.sh` for a movie archive.
    1. `tv_list.sh` for a TV show archive.
1. Import the result CSV into a spreadseet.
1. Copy the cells from the imported CSV data into your new sheet at cell `A4`.
1. Sort the individual archive file lines as you wish, for readability.

## Movie lists
```bash
./movie_list.sh directory > ./archive.csv
```
## TV lists
```bash
./tv_list.sh directory > ./archive.csv
```

[jellyfin]: https://www.plex.tv/
[plex]: https://www.plex.tv/
[kodi]: https://kodi.tv/
