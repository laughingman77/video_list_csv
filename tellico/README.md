# Using video_list_csv with Tellico

Although [Tellico][tellico] is a little long in the tooth, it still a great way to maintain large catalogues of media, allowing you to search and browse the movies and TV shows (plus it's free!).

There are plugins to automatically fetch all metadata on the media from [OMDb API][omdb] and [TVmaze API][tvmaze].

## Configuration

1. Install Tellico from: [Tellico][tellico_download].
1. An `env` file has been configured to generate data that `Tellico` can use. Copy `tellico.env` to `.env`:
    ```
    cd video_list_csv
    cp tellico/tellico.env .env
    ```
1. Archive templates have been set up with required fields to store and display data from `video_list_csv`, and then populate from the APIs.Copy the archive templates to your home directory:
    ```
    cp tellico/movie_archive_template.tc ~/movie_archive.tc
    cp tellico/tv_archive_template.tc ~/tv_archive.tc
    ```
1. Apply for an API Key at [OMDb][omdb_key] and store the key somewhere safe.
1. Configure `Tellico`:
    1. Click on `Settings` -> `Configure Tellico...`
    1. Click on the `Data Sources` tab.
    1. Click on the `New...` button.
        1. Select `The Open Movie Database` from `Source Type`.
        1. Paste your API key into `Access Key`.
        1. Click on `OK`.
    1. Click on the `New...` button.
        1. Select `TVmaze` from `Source Type`.
        1. Click on `OK`.

## Importing your archive into Tellico

1. Generate a `CSV` archive file of your media directory:
    ```
    ./video_list_csv </my/media/directory/> > ~/archive.csv
    ```
    
### Movie archive CSV:

1. Open `~/movie_archive.tc`.
1. Click on `File` -> `Import` -> `Import CSV Data...`.
1. Select the `~/archive.csv` file.
1. Select all of the new items.
1. Right Click on them and select `Edit Entries...`.
1. Click on the `Features` tab.
1. Enter the Disk name or location in the `Disk` field.
1. Click on `Save Entries`.
1. Right Click on them and select `Update Entries` -> `The Open Movie Database`.
    
### TV archive CSV:

1. Open `~/tv_archive.tc`.
1. Click on `File` -> `Import` -> `Import CSV Data...`.
1. Select the `~/archive.csv` file.
1. Select all of the new items.
1. Right Click on them and select `Edit Entries...`.
1. Click on the `Features` tab.
1. Enter the Disk name or location in the `Disk` field.
1. Click on `Save Entries`.
1. Right Click on them and select `Update Entries` -> `TVmaze`.

[tellico]: https://tellico-project.org/
[tellico_download]: https://tellico-project.org/download-tellico/
[omdb]: https://www.omdbapi.com/
[omdb_key]: https://www.omdbapi.com/apikey.aspx
[tvmaze]: https://www.tvmaze.com/api
[readme]: ../README.md
