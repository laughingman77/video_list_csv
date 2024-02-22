# video_list_csv

Recursively create a CSV with details of all movie and TV media in a directory. Useful for cataloguing archive disks.

The script assumes separate archives for TV or Movie media, and automatically detects what kind of archive it is scanning and renders the appropriate columns.

You can define what columns you want to render as well as customise the order in the `.env` file.

The result CVS also contains summary data of `Disk Space used` and `Disk Space free`. This allows you to see free disk space after your media centre's metadata is taken into account.

## Disclaimer

This script is intended for people who want to maintain an archive of legitmately backed up or original videos. However, it does contain possible configuration to list `Release type` of a video, this is specific to pirated media (see [Pirated movie release types][release_types]). **We do not condone Piracy in any way, it is against the law**, and this feature has only been added for completeness and nerdiness.

# Install

## Requirements

* git
* jq (if using the `detect_resolution` option)
* ffmpeg (if using the `detect_resolution` option)

```bash
sudo apt install git jq ffmpeg
```

## Clone the reposirory

```bash
git clone git@github.com:laughingman77/video_list_csv.git
```
    
# Configure

The `.env` contains the configuration for various options in the script. The `example.env` contains all of the default settings. Copy `example.env` to `.env` and, if needed, configure `.env` to your requirements.

```bash
cp example.env .env
```

# Usage

1. Make a copy of the spreadsheet
1. Duplicate the `Archive Template` sheet for your archive disk
1. Run the script:
    ```bash
    ./archive_list.sh directory > ./archive.csv
    ```
1. Import the result CSV into a spreadseet.
1. Copy the cells from the imported CSV data into your new sheet at cell `A4`.
1. Sort the individual archive file lines as you wish, for readability.

# .env options

* `detect_resolution`: (0 or 1) If the video resolution is not in the filename, then automatically detect it.
* `display_season_for_1`: (0 or 1) Only extract the season number if the episode is `01`, it makes a TV ist more readable.
* `display_series_for_1`: (0 or 1) Only extract the series name if the season and episode are `01`, it makes a TV ist more readable.
* `tv_columns`: TV list columns to render, and their order.
* `movie_columns`: Movie list columns to render, and their order.

## Columns config

By configuring the `tv_columns` and `movie_columns`, you can dictate which columns are rendered and in what order. The possible columns are:

* `Series`: (Only for TV series) the TV series title.
* `Title`: (Only for Movies) the Movie title.
* `Year`: Relese date
* `Season`: (Only for TV series) the TV series season.
* `Episode`: (Only for TV series) the TV series season.
* `Resolution`: Video resolution (480p, 720p, 1080p, 2160, etc)
* `Version`: (Jellyin specific) The relase version, ie. `Director's Cut`.
* `Release Type`: (not in the default configuration) Pirated release type - NOT recommended
* `Size (GB)`: File size in GB
* `Size (MB)`: (not in the default configuration) File size in MB
* `Size (KB)`: (not in the default configuration) File size in KB
* `Size (B)`: (not in the default configuration) File size in B
* `Filename`: Filename
* `Full Path`: (not in the default configuration) Absolute filepath and filename

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

**Note:** In order to group the TV shows correctly, the filenames must all have exactly the same series name (including capitalisation).

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

[jellyfin]: https://www.plex.tv/
[plex]: https://www.plex.tv/
[kodi]: https://kodi.tv/
[release_types]: https://en.wikipedia.org/wiki/Pirated_movie_release_types
