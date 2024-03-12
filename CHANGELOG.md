## Mar 12
* Added scanner ability for `ffprobe` or `mediainfo`
* Fixed `HDR10` and `HDR10+` detection with `mediainfio`
* Enabled lomg names where possible for subtitles
* Tightened up consistency for codec naming
## Mar 7
* Added a progress bar for better UX
* Supress the annoying `find: ‘.../lost+found’: Permission denied` - which is a system directory anyway
* Added a `Subtitles` column
* Added a `force_detect` option to the config
# Tag v3.1.0
## Mar 5
* Migrated from `ffrpobe` to `mediainfo` (dependenciesa changed)
* Added validation at the start of the script for the necessary dependencies
* Added detection for DV, HDR10 & HDR10+
* Tightened up the scan speed.
# Tag v3.0.0
## Mar 2
* Added handlling for multiple video/audio streams
## 29 Feb 2024
* Code optimisation (at least x2 faster)
## 28 Feb 2024
* POSIX compliance (requires change in `.env` for arrays)
# Tag v2.0.0
## 27 Feb 2024
* Minor bugfixes and enhancements
## 26 Feb 2024
* Added Audio column
* All columns active by default, except Release Type
## 25 Feb 2024
* Added Video column
## 24 Feb 2024
* Renamed Version column to Edition
## 22 Feb 2024
* Merged `tv_list.sh` & `movie_list.sh` into `archive_list.sh`
* Automatic detection of TV or movie archive
* Configurable columns in the result CSV
* Option to group TV files by series & season  
* Added extra columns if wanted
* Updated the README
# Tag v1.0.0
## 19 Feb 2024
* Bug fix and add optional resolution detection
