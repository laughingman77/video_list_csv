# video_list_csv

## Overview

This script recursively scans a directory and creates a CSV with details of all Movie and TV media in that directory and sub-directories. This is aimed towards Home Theatre enthusiasts and their archives. However it can be used for any directories containing video media.

The script uses `ffprobe` or `mediainfo` to scan the library. It can automatically detect which libraries are present, or you can define what package you want to use as a CLI argument or globally in the `.env` file.

This is a POSIX compliant bash script. It will work on all Linux and Mac systems. Windows users will be able to run the script using WSL (see [How to run .sh or Shell Script file in Windows 11/10][wsl]) (untested).

The script assumes that you have separate archives for TV and movies and automatically detects what kind of archive it is scanning and renders the appropriate archive list. You can also define what kind of list you want as a CLI argument or globally in the `.env` file.

You can define what columns you want in the CSV and the order in the settings file. An extra `Sort` column is automatically added to the end of the columns, to allow proper sorting (no other columns are 100% reliable).

The resultant CVS contains summary data of `Disk Size`, `Disk Space used` and `Disk Space free`. This allows you to see free disk space after other files in the archive are taken into account.

**Note:** The scan will be fastest if you have the media info in the filename.

**Note:**  The automatic detection is based on the format of the first video filename that the script parses. If you have extras in your archive, you may want to specify the archive type as a CLI option: `-t {tv,movie}`.

**Note:** `ffprobe` is much faster than `mediainfo`, however it cannot fetch `HDR10` or `HDR10+` definitions at the present.

## Disclaimer

This script is intended for people who want to maintain an archive of legitmately backed up or original videos. However, it does contain possible configuration to list `Release type` of a video, this is specific to pirated media (see [Pirated movie release types][release_types]). **We do not condone Piracy in any way, it is against the law**, and this feature has only been added for completeness and nerdiness.

# Installation

## Requirements

* `git`
* `jq`
* `ffprobe` or `mediainfo`

### To use `ffprobe` (default scanner)

```bash
sudo apt install git jq bc ffprobe
```

### To use `mediainfo`

```bash
sudo apt install git jq bc mediainfo
```

## Clone the reposirory

```bash
git clone git@github.com:laughingman77/video_list_csv.git
```
    
# Configuration

The `.env` file contains the configuration for various options in the script. The `example.env` contains all of the default settings. Copy `example.env` to `.env` and, if needed, configure `.env` to your requirements:

```bash
cd video_list_csv && cp example.env .env
```

# Usage

## Spreadsheet

Maintain a catalogue of your video media in a spreadsheet:

1. Copy the `Movie Archive.xlsx` spreadsheet into your home directory.
1. In your new spreadsheet, duplicate the `Archive Template` sheet, and give it a meaningful name.
1. Run the script:
    ```bash
    sh video_list_csv.sh /path/to/video/dir/ > ~/archive.csv
    ```
    Or
    ```bash
    ./video_list_csv.sh /path/to/video/dir/ > ~/archive.csv
    ```
1. Import `archive.csv` into your spreadsheet program.
1. Copy the cells from the imported CSV data and paste it into your archive sheet at cell `A4`.
1. Select the cells for the media data and sort by the `Sort` column.
1. Format the sheet to your preference.

## CLI Options

CLI options allow you to override the values in `.env`:

* `-a, --trim-release-type` Trim any `Release type` words from the `Edition column` (0 or 1).
* `-b, --trim-resolution` Trim any `Resolution` words from the `Edition column` (0 or 1).
* `-h, -?, --help` Display the help text.
* `-i, --default-stream`: Display only the default streams for audio and video (0 or 1).
* `-s, --scanner` Set the scanner program (`ffprobe` or `mediainfo`).
* `-t, --type` Set the archive type (`tv` or `movie`).
* `-f, --force` Force detect the media metadata from the file (0 or 1).
* `-d, --detect` Detect the media metadata if not in the filename (0 or 1).
* `-e, --season` Display season only when episode is #1 (0 or 1).
* `-r, --series` Display series only when season is #1 and episode is #1 (0 or 1).
* `-x, --movie_columns` Define the Movie columns.
* `-z, --tv_columns` Define the TV columns.

# .env options

* `scanner`: (`ffprobe`, `mediainfo`) Select the preferred scanning program globally. If not set, then ffprobe takes preference but will fallback to mediainfo if it's not detected.
* `type`: (`tv` or `movie`) Set the archive media type globally.
* `detect_if_not_in_filename`: (0 or 1) If the audio/audio formats or resolution are not detected in the filename, then automatically detect them.
* `trim_release_type`: (0 or 1) Trim any `Release type` words from the `Edition column`.
* `trim_resolution`: (0 or 1) Trim any `Resolution` words from the `Edition column`.
* `default_stream`: Only display the default streams (reverts to diplsaying all streams if no stream set to default). This affects the `Audio`, `Video` and `Resolution` columns.
* `force_detect`: (0 or 1) Force detection of the video streams on all videos (this will override `detect_if_not_in_filename` and ignore any values found in the filename for the `Resolution`/`Video`/`Audio` columns).
* `display_season_for_1`: (0 or 1) Only extract the season number if the episode is `01`, it makes a TV list more readable.
* `display_series_for_1`: (0 or 1) Only extract the series name if the season and episode are `01`, it makes a TV list more readable.
* `tv_columns`: TV archive columns to render, and their order.
* `movie_columns`: Movie archive columns to render, and their order.

## Columns config

By configuring the `tv_columns` and `movie_columns`, you can dictate which columns are rendered and in what order.

The column names are separated by the `|` character.

The possible columns are:

* `Title`: (Only for **Movies**) the Movie title.
* `Edition`: (Only for  **Movies**) the release edition, ie. `Director's Cut`, `Cinematic Cut`, `Special Edition`, `Unrated`, `Uncut` etc.
* `Series`: (Only for **TV series**) the TV series title.
* `Season`: (Only for **TV series**) the TV series season.
* `Episode`: (Only for **TV series**) the TV series episode.
* `Number`: (Only for **TV series**) the TV series episode (this is for `Tellico` integration).
* `Year`: Relese date.
* `Production Year`: same as `Year` (this is for `Tellico` integration).
* `Resolution`: Video resolution (480p, 720p, 1080p, 2160, etc).
* `Video`: The video codec.
* `Running Time`: The video running time in minutes (this is for `Tellico` integration).
* `Running Time (s)`: The video running time in seconds.
* `Running Time (m)`: The video running time in minutes.
* `Running Time (h)`: The video running time in hours.
* `Running Time (h/m)`: The video running time in hours and minutes.
* `Running Time (h/m/s)`: The video running time in hours, minutes and seconds.
* `Video Tracks`: Same as `Video` (this is for `Tellico` integration).
* `Colour Mode`: The video coloration mode (ie. `HLG`, `DV`, `HDR`, `HDR10+`, etc).
* `Audio`: The audio codec, channel layout and language.
* `Audio Tracks`: Same as `Audio` (this is for `Tellico` integration).
* `Subtitles`: The list of subtitle srteam/s.
* `Subtitle Languages`: Same as `Subtitles` (this is for `Tellico` integration).
* `Release Type`: (**not in the default configuration**) Pirated release type - NOT recommended.
* `Size (GB)`: File size in GB.
* `Size (MB)`: File size in MB.
* `Size (KB)`: File size in KB.
* `Size (B)`: File size in B.
* `Filename`: Filename.
* `Full Path`: Absolute filepath and filename (this includes the mount path if the archive disk is an external disk).

# Directory and Filenames

The script is designed for the directory and filenaming structure of [Jellyfin][jellyfin], [Plex][plex] and [Kodi][kodi].

The script assumes a separator of `space` or `period` between words in the filename, and will do its best to detect items. Usage of `hyphen` could not be added to the detection, due to too many false positives.

All TV episodes should be in the format of `S[0-9]{2}E[0-9]{2}` (case-insensitive), examples:

* S01E01
* s01e01

# Multiple audio/video streams

if `default_stream` is set to `0` in the .env and the script falls-back to probing the video file:

* If there is only one stream, it will list only the codec, as if it were in the filename, eg:
    ```
    "AVC DV HDR10+ (en)"
    ```
* If there are multiple streams, it will list each stream number and its codec in a comma separated list, eg:
    ```
    "stream_1: DTS 5.1 (en), stream_2: AC3 2.0 (za)"
    ```

# Tellico

Maintain a catalogue of your video media in Tellico, see [tellico/README.md](./tellico/README.md).

# Testing

## Locally

Ensure you have installed `shellcheck`:

```bash
sudo apt install shellcheck
```

A script has ben created to manually lint all files, run:

```bash
cd video_list_csv
./test.sh
```

Expected output:

```bash
$ ./test.sh 
.env does not exist, generating the default .env...
Checking ./test.sh
OK
Checking ./video_list_csv.sh
OK
Checking ./includes/progressbar.sh
OK
Checking ./includes/functions.sh
OK
Checking ./includes/ffprobe.sh
OK
Checking ./includes/archive_list.sh
OK
Checking ./includes/mediainfo.sh
OK
Checking ./archive_list.sh
OK
```

## Simulate GitHub Actions locally

CI/CD linting is implemented using GitHub Actions. You can run the pipelines locally, using [nektos/act][act]:

```bash
apt install act
cd video_list_csv
sudo act
```

This should give output similar to:

```bash
...
| beginning shell linting...
| not excluding any dirs
| finding and linting all shell scripts/files via shellcheck...
| [PASS]: shellcheck - successfully linted: ./ffprobe.sh
| [PASS]: shellcheck - successfully linted: ./archive_list.sh
| [PASS]: shellcheck - successfully linted: ./test.sh
| [PASS]: shellcheck - successfully linted: ./mediainfo.sh
| [PASS]: shellcheck - successfully linted: ./progressbar.sh
| finding and linting all files with shell shebangs via shellcheck...
| looking for subdirectories of bin directories that are not usable via PATH...
| looking for programs in PATH that have a filename suffix
| done
...
```

# Thanks To

Awesome online aplications used in development and testing:

* JSONLint: https://jsonlint.com/
* JSON Pretty Print: https://jsonformatter.org/json-pretty-print
* jq kung fu: https://jqkungfu.com/

Technical experts:

* Progressbar inspiration: https://github.com/albertomosconi/posixbar
* Parse command line options for a shell script (POSIX): https://gist.github.com/deshion/10d3cb5f88a21671e17a
* Pseudo arrays: https://gist.github.com/biiont/290341b29657c0bb2df6
* Padding a string: https://stackoverflow.com/a/74964817
* Validation of dependencies: https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script
* Line count in a variable: https://unix.stackexchange.com/questions/482893/how-to-posix-ly-count-the-number-of-lines-in-a-string-variable
* Suppress Permission Denied messages: https://stackoverflow.com/questions/762348/how-can-i-exclude-all-permission-denied-messages-from-find

[jellyfin]: https://www.plex.tv/
[plex]: https://www.plex.tv/
[kodi]: https://kodi.tv/
[release_types]: https://en.wikipedia.org/wiki/Pirated_movie_release_types
[wsl]: https://www.thewindowsclub.com/how-to-run-sh-or-shell-script-file-in-windows-10
[ffmpeg-6]: https://ubuntuhandbook.org/index.php/2023/03/ffmpeg-6-0-released-how-to-install-in-ubuntu-22-04-20-04/
[act]: https://github.com/nektos/act
