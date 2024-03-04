# video_list_csv

## Overview

This script recursively scans a directory and creates a CSV with details of all Movie and TV media in that directory and sub-directories. This is aimed towards Home Theatre enthusiasts and their archives. However it can be used for any directories containing video media.

This is a POSIX compliant bash script. It will work on all Linux and Mac systems. Windows users will be able to run the script using WSL (see [How to run .sh or Shell Script file in Windows 11/10][wsl]).

The script assumes these are separate archives for TV or Movie media, and automatically detects what kind of archive it is scanning and renders the appropriate archive list.

You can define what columns you want to render and the order in the settings file.

The resultant CVS also contains summary data of `Disk Size`, `Disk Space used` and `Disk Space free`. This allows you to see free disk space after other files in the archive are taken into account.

## Disclaimer

This script is intended for people who want to maintain an archive of legitmately backed up or original videos. However, it does contain possible configuration to list `Release type` of a video, this is specific to pirated media (see [Pirated movie release types][release_types]). **We do not condone Piracy in any way, it is against the law**, and this feature has only been added for completeness and nerdiness.

# Installation

## Requirements

* git
* jq
* mediainfo

```bash
sudo apt install git jq mediainfo
```

## Clone the reposirory

```bash
git clone git@github.com:laughingman77/video_list_csv.git
```
    
# Configuration

The `.env` file contains the configuration for various options in the script. The `example.env` contains all of the default settings. Copy `example.env` to `.env` and, if needed, configure `.env` to your requirements.

```bash
cp example.env .env
```

# Usage

1. Copy the `Movie Archive` spreadsheet into your home directory.
1. In your new spreadsheet, duplicate the `Archive Template` sheet for your archive disk, and give it a meaningful name.
1. Run the script:
    ```bash
    sh archive_list.sh /path/to/archive/dir/ > ./archive.csv
    ```
    or
    ```bash
    ./archive_list.sh /path/to/archive/dir/ > ./archive.csv
    ```
1. Import `archive.csv` into your spreadseet program.
1. Copy the cells from the imported CSV data and paste it into your archive sheet at cell `A4`.
1. Sort the individual archive file rows as you wish, for readability.

# .env options

* `detect_if_not_in_filename`: (0 or 1) If the audio/audio formats or resolution are not detected in the filename, then automatically detect them.
* `display_season_for_1`: (0 or 1) Only extract the season number if the episode is `01`, it makes a TV list more readable.
* `display_series_for_1`: (0 or 1) Only extract the series name if the season and episode are `01`, it makes a TV list more readable.
* `tv_columns`: TV archive columns to render, and their order.
* `movie_columns`: Movie archive columns to render, and their order.

## Columns config

By configuring the `tv_columns` and `movie_columns`, you can dictate which columns are rendered and in what order.

The column names are separated by the `|` character.

The possible columns are:

* `Title`: (Only for Movies) the Movie title.
* `Edition`: (Only for Movies) the release edition, ie. `Director's Cut`, `Cinematic Cut`, `Special Edition`, `Unrated`, `Uncut` etc.
* `Series`: (Only for TV series) the TV series title.
* `Season`: (Only for TV series) the TV series season.
* `Episode`: (Only for TV series) the TV series episode.
* `Year`: Relese date
* `Resolution`: Video resolution (480p, 720p, 1080p, 2160, etc)
* `Video`: The video codec and colouration, ie. `DV`, `AVC`, `HEVC`, `HDR10+`, etc
* `Audio`: the ausio codec and channel layout
* `Release Type`: (not in the default configuration) Pirated release type - NOT recommended
* `Size (GB)`: File size in GB
* `Size (MB)`: File size in MB
* `Size (KB)`: File size in KB
* `Size (B)`: File size in B
* `Filename`: Filename
* `Full Path`: Absolute filepath and filename (this includes the mount path if the archive disk is an external disk)

# Directory and Filenames

The script is designed for the directory and filenaming structure of [Jellyfin][jellyfin], [Plex][plex] and [Kodi][kodi].

The script assumes a separator of `space` or `period` between words in the filename, and will do its best to detect items. Usage of `hyphen` could not be added to the detection, due to too many false positives.

All TV episodes should be in the format of `S[0-9]{2}E[0-9]{2}` (case-insensitive), examples:

* S01E01
* s01e01

# Multiple audio/video streams

If you have set `detect_if_not_in_filename=1` in the `.env` and the script falls-back to probing the viedo file:

* If there is only one stream, it will list only the codec, as if it were in the filename, i.e.:

    `"DTS 5.1"`
* If there are multiple streams, it will list each stream number and its codec in a comma separated list, i.e.:

    `"stream_1:DTS 5.1, stream_2:AC3 2.0"`

[jellyfin]: https://www.plex.tv/
[plex]: https://www.plex.tv/
[kodi]: https://kodi.tv/
[release_types]: https://en.wikipedia.org/wiki/Pirated_movie_release_types
[wsl]: https://www.thewindowsclub.com/how-to-run-sh-or-shell-script-file-in-windows-10
