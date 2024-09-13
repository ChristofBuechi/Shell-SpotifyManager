# Shell-SpotifyManager

## Overview

Shell-SpotifyManager provides simple scripts to manage your favorite Spotify albums and songs directly from the command line. This script is designed to help users quickly delete tracks or albums from their Spotify library, as the Spotify UI can be cumbersome for deleting multiple entries at once. The script will prompt you for each entry, but it speeds up the process by requiring only `y` or `n` as inputs to confirm deletion.

## Features

- **Delete favorite albums**: Easily manage and remove albums from your favorites list via the command line.
- **Delete liked songs**: Remove songs from your liked tracks list, even if you have thousands of favorites.
- **OAuth Flow Integration**: Automatically handles the OAuth flow with Spotify, retrieving access tokens without manual input.
- **Streamlined Input**: Provides a simple yes/no prompt for each entry, making it much faster than navigating through the Spotify UI.

## Requirements

- **Spotify Developer App**: 
  - You must create an app on the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) to get the `Client ID` and `Client Secret` required for API access.
  
- **Dependencies**:
  - **`jq`**: A lightweight and flexible command-line JSON processor to parse the Spotify API's JSON responses.
  - **`Python`**: Required for creating a local server to handle the OAuth callback (used in the `manage_favorite_tracks_automated.sh` script).
  
## Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/ChristofBuechi/Shell-SpotifyManager.git
    cd Shell-SpotifyManager
    ```

2. Install `jq`:
    - **Ubuntu/Debian**:
      ```bash
      sudo apt-get install jq
      ```
    - **MacOS** (using Homebrew):
      ```bash
      brew install jq
      ```

3. Ensure Python is installed:
    - **MacOS/Ubuntu**:
      Python is generally pre-installed. You can verify this by running:
      ```bash
      python3 --version
      ```

4. Set up your Spotify Developer credentials:
    - Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
    - Create a new app and note down the `Client ID` and `Client Secret`.
    - Set the Redirect URI in the Spotify Dashboard to: `http://localhost:8888/callback`.

5. Update the script with your credentials:
    In both `manage_favorite_albums.sh` and `manage_favorite_tracks_automated.sh`, replace the placeholders with your `CLIENT_ID`, `CLIENT_SECRET`, and `REDIRECT_URI`.

## Usage

### Manage Favorite Albums

1. Run the script to remove favorite albums:
    ```bash
    ./manage_favorite_albums.sh
    ```
2. The script will list all your favorite albums and ask if you want to delete each one by showing the album, artist, and tracks. Simply type `y` to delete or `n` to keep the album.

### Manage Liked Tracks

1. Run the script to manage your liked songs:
    ```bash
    ./manage_favorite_tracks_automated.sh
    ```
2. The script will list your liked tracks (oldest first) and prompt you for each one. Type `y` to delete or `n` to keep the song in your liked list.

## Notes

- The Spotify API limits requests to 50 tracks or albums per call. The scripts handle pagination to manage large lists (e.g., over 1,400 tracks).
- This script requires internet access for API communication.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
