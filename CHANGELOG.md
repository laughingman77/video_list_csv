## 9/11/2024
* Added `Running Time` columns.
# Tag v1.0.0
## 29/8/2024
* Initial tag, recreation of `v3.4.4.1` from the old repository

# ~~Old Repository~~

## ~~Tag v3.4.4.1~~
### ~~28/8/2024~~
* ~~Correctly handle double quotes~~
* ~~Updated Tellico templates for the new field sets~~
### ~~27/8/2024~~
* ~~Deprecate the new `Aspect Ratio` column. This conflicts with Tellico's `Internet Movie Database` data-source plugin and was the wrong name~~
## ~~Tag v3.4.4~~
### ~~24/8/2024~~
* ~~Fix minor issues in the exalple Tellico configs~~
* ~~Separate the `Colour Mode` attributes from the `Video` column~~
## ~~Tag v3.4.3~~
### ~~27/5/2024~~
* ~~Implemented Tellico intergration~~
## ~~Tag v3.4.2~~
### ~~14/5/2024~~
* ~~Implemented default settings~~
* ~~Option to display only the default audio/video streams~~
## ~~Tag v3.4.1~~
### ~~15/4/2024~~
* ~~Fix issue with empty `Release Type` column~~
## ~~Tag v3.4.0~~
### ~~14/4/2024~~
* ~~Restructured core scripts~~
* ~~Added CLI args for all env parameters~~
* ~~Option to satrip resolution and/or release from the title~~
* ~~Add language code to the audio stream/s column~~
## ~~Tag v3.3.0~~
### ~~28/3/2024~~
* ~~Handle extras diretories~~
## ~~Tag v3.2.1~~
### ~~15/3/2024~~
* ~~Fixed all issues breaking the scripts running in a bash environment (arch linux)~~
* ~~Added GitHub actions for automated shellcheck linting~~
* ~~Added new test.sh for local testing of all bash scripts~~
* ~~Fixed columns in example.env somehow reverting to array vars~~
## ~~Tag v3.2.0~~
### ~~12/3/2024~~
* ~~Added scanner ability for `ffprobe` or `mediainfo`~~
* ~~Fixed `HDR10` and `HDR10+` detection with `mediainfo`~~
* ~~Tightened up consistency for codec naming~~
### ~~7/3/2024~~
* ~~Added a progress bar for better UX~~
* ~~Supress the annoying `find: ‘.../lost+found’: Permission denied` - which is a system directory anyway~~
* ~~Added a `Subtitles` column~~
* ~~Added a `force_detect` option to the config~~
## ~~Tag v3.1.0~~
### ~~5/3/2024~~
* ~~Migrated from `ffrpobe` to `mediainfo` (dependenciesa changed)~~
* ~~Added validation at the start of the script for the necessary dependencies~~
* ~~Added detection for DV, HDR10 & HDR10+~~
* ~~Tightened up the scan speed.~~
## ~~Tag v3.0.0~~
### ~~2/3/2024~~
* ~~Added handlling for multiple video/audio streams~~
### ~~29/2/2024~~
* ~~Code optimisation (at least x2 faster)~~
### ~~28/2/2024~~
* ~~POSIX compliance (requires change in `.env` for arrays)~~
## ~~Tag v2.0.0~~
### ~~27/2/2024~~
* ~~Minor bugfixes and enhancements~~
### ~~26/2/2024~~
* ~~Added Audio column~~
* ~~All columns active by default, except Release Type~~
### ~~25/2/2024~~
* ~~Added Video column~~
### ~~24/2/2024~~
* ~~Renamed Version co~~lumn to Edition~~
### ~~22/2/2024~~
* ~~Merged `tv_list.sh` & `movie_list.sh` into `archive_list.sh`~~
* ~~Automatic detection of TV or movie archive~~
* ~~Configurable columns in the result CSV~~
* ~~Option to group TV files by series & season  ~~
* ~~Added extra columns if wanted~~
* ~~Updated the README~~
## ~~Tag v1.0.0~~
### ~~19/2/2024~~
* ~~Bug fix and add optional resolution detection~~
