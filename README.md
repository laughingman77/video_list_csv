# video_list_csv

Recursively create a CSV with details of all movie and TV media in a directory. Useful for cataloguing archive disks.

The result CVS also contains summary data of `Disk Space used` and `Disk Space free`. This allows you to see free disk space after your media centre's metadata is taken into account.

## Disclaimer

This script is intended for people who want to maintain an archive of legitmately backed up or original videos. However. it does contain possible configuration to list `Release type` of a video, this is specific to pirated media (see [Pirated movie release types][release_types]). **We do not condone Piracy in any way, it is against the law**, and this feature has only been added for completeness.

# Install

## Requirements

* git
* jq
* ffmpeg

```bash
sudo apt install git jq ffmpeg
```

## Clone the reposirory

```bash
git clone git@github.com:laughingman77/video_list_csv.git
```
    
# Configure

The `.env` contains the configuration for various options in the script. The `example.env` contains all options and suggested settings. Copy `example.env` to `.env` and configure `.env` to your requirements.

```bash
cp example.env .env
```

## Options

* `movie_columns` - (0 or 1) If the video resolution is not in the filename, the automatically detect it.

# Directory and Filenames

The script assumes the directory and filenaming structure for [Jellyfin][jellyfin].

This format is broadly compatible with [kodi][kodi] and [plex][plex]. However the main differences will be with:

* different movie versions, where [jellyfin][jellyfin] uses the ` - ` to separate version text from filename text.
* `tmdbid` and `imdbid` codes.

## Movies

```
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

**Note:** In order to group the TV shows correctly, the filenames must all have exactly the same series name (and capitalisation).

```
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
[release_types]: https://en.wikipedia.org/wiki/Pirated_movie_release_types