#!/bin/bash

# Spotify API credentials
CLIENT_ID="ff681234610049e4bd94cde20442956b"
CLIENT_SECRET="" # removed
REDIRECT_URI="http://localhost:8888/callback"  # z.B. http://localhost:8888/callback

# Hilfsvariable für das Speichern des Tokens
ACCESS_TOKEN=""

# OAuth 2.0 Flow: Benutzerlogin und Authentifizierung
get_new_access_token() {
    echo "Öffne den folgenden Link in deinem Browser und logge dich ein:"
    echo "https://accounts.spotify.com/authorize?client_id=$CLIENT_ID&response_type=code&redirect_uri=$REDIRECT_URI&scope=user-library-read%20user-library-modify"

    echo "Gib den Auth-Code hier ein:"
    read AUTH_CODE

    TOKEN_RESPONSE=$(curl -s -X POST -d grant_type=authorization_code -d code="$AUTH_CODE" -d redirect_uri="$REDIRECT_URI" -u "$CLIENT_ID:$CLIENT_SECRET" https://accounts.spotify.com/api/token)
    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r .access_token)
    echo "Access Token erhalten: $ACCESS_TOKEN"
}

# Fragt den Benutzer, ob er das Access Token manuell eingeben möchte oder den OAuth-Flow durchlaufen will
get_user_access_token() {
    read -p "Möchtest du ein Access Token manuell eingeben? (y/n): " use_manual_token
    if [[ "$use_manual_token" == "y" ]]; then
        echo "Bitte gib deinen Spotify Access Token ein:"
        read ACCESS_TOKEN
    else
        get_new_access_token
    fi
}

# Alben aus Favoriten abrufen
get_saved_albums() {
    curl -s -X GET "https://api.spotify.com/v1/me/albums?limit=500" -H "Authorization: Bearer $ACCESS_TOKEN"
}

# Details zum Album anzeigen: Name, Künstler, Tracks
show_album_details() {
    local album=$1
    local album_name=$(echo "$album" | jq -r '.album.name')
    local artist_name=$(echo "$album" | jq -r '.album.artists[0].name')
    local tracks=$(echo "$album" | jq -r '.album.tracks.items[].name')

    echo "============================"
    echo "🎵 Album: $album_name"
    echo "🎤 Künstler: $artist_name"
    echo "🎶 Tracks:"
    while IFS= read -r track; do
        echo "   - $track"
    done <<< "$tracks"
    echo "============================"
}

# Fragt den Benutzer, ob ein Album entfernt werden soll
ask_to_remove_album() {
    local album_id=$1
    local album_name=$2

    # Benutzer fragen
    local response
    read -p "Möchtest du das Album \"$album_name\" aus deinen Favoriten entfernen? (y/n): " response
    if [[ "$response" == "y" ]]; then
        remove_album_from_favorites "$album_id"
    else
        echo "\"$album_name\" bleibt in deinen Favoriten."
    fi
}

# Entfernt ein Album aus den Favoriten
remove_album_from_favorites() {
    local album_id=$1
    curl -s -X DELETE "https://api.spotify.com/v1/me/albums?ids=$album_id" -H "Authorization: Bearer $ACCESS_TOKEN"
    echo "Album mit ID $album_id wurde aus den Favoriten entfernt."
}

# Hauptfunktion
main() {
    # Hole den Benutzerzugriffstoken
    get_user_access_token

    # Rufe gespeicherte Alben ab
    saved_albums=$(get_saved_albums)

    # Durchlaufe alle gespeicherten Alben und zeige sie einzeln an
    album_count=$(echo "$saved_albums" | jq -r '.items | length')
    
    for ((i=0; i<album_count; i++)); do
        album=$(echo "$saved_albums" | jq -c ".items[$i]")

        album_id=$(echo "$album" | jq -r '.album.id')
        album_name=$(echo "$album" | jq -r '.album.name')

        # Albumdetails anzeigen
        show_album_details "$album"

        # Benutzer fragen, ob das Album entfernt werden soll
        ask_to_remove_album "$album_id" "$album_name"
    done
}

# Starte das Skript
main