#!/bin/bash

# Spotify API credentials
CLIENT_ID="ff681234610049e4bd94cde20442956b"
CLIENT_SECRET="" # removed
REDIRECT_URI="http://localhost:8888/callback"  # z.B. http://localhost:8888/callback

# Hilfsvariable für das Speichern des Tokens
ACCESS_TOKEN=""

# Funktion, um einen Webserver mit Python zu starten und den Auth-Code zu empfangen
start_auth_server() {
    echo "Starte lokalen Webserver auf http://localhost:8888/callback und warte auf den Auth-Code..."

    # Starte Python-HTTP-Server und warte auf den Auth-Code
    python3 -m http.server 8888 > server.log 2>&1 &
    SERVER_PID=$!

    sleep 10  # Warte, bis der Benutzer den Auth-Code eingibt

    # Finde die Auth-Code-Anfrage im Server-Log
    AUTH_CODE=$(grep "GET /callback?code=" server.log | sed -n 's/.*code=\([^ ]*\).*/\1/p')

    # Beende den Python-Server
    kill $SERVER_PID

    if [ -z "$AUTH_CODE" ]; then
        echo "Fehler beim Empfang des Auth-Codes."
    else
        echo "Empfangener Auth-Code: $AUTH_CODE"
    fi
}


# OAuth 2.0 Flow: Benutzerlogin und Authentifizierung
get_new_access_token() {
    echo "Öffne den folgenden Link in deinem Browser und logge dich ein:"
    echo "https://accounts.spotify.com/authorize?client_id=$CLIENT_ID&response_type=code&redirect_uri=$REDIRECT_URI&scope=user-library-read%20user-library-modify"

    # Starte den Webserver und warte auf den Auth-Code
    start_auth_server

    # Verwende den erhaltenen Auth-Code, um den Access-Token abzurufen
    TOKEN_RESPONSE=$(curl -s -X POST -d grant_type=authorization_code -d code="$AUTH_CODE" -d redirect_uri="$REDIRECT_URI" -u "$CLIENT_ID:$CLIENT_SECRET" https://accounts.spotify.com/api/token)
    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r .access_token)
    echo "Access Token erhalten: $ACCESS_TOKEN"
}

# Tracks aus "Liked Tracks" abrufen mit Paginierung
get_liked_tracks() {
    local offset=$1
    curl -s -X GET "https://api.spotify.com/v1/me/tracks?limit=50&offset=$offset" -H "Authorization: Bearer $ACCESS_TOKEN"
}

# Details zum Track anzeigen: Name, Künstler, Album
show_track_details() {
    local track=$1
    local track_name=$(echo "$track" | jq -r '.track.name')
    local artist_name=$(echo "$track" | jq -r '.track.artists[0].name')
    local album_name=$(echo "$track" | jq -r '.track.album.name')

    echo "============================"
    echo "🎵 Track: $track_name"
    echo "🎤 Künstler: $artist_name"
    echo "💿 Album: $album_name"
    echo "============================"
}

# Fragt den Benutzer, ob ein Track entfernt werden soll, ohne Enter-Taste zu drücken
ask_to_remove_track() {
    local track_id=$1
    local track_name=$2

    # Benutzer fragen, ohne Enter-Taste zu erfordern
    while true; do
        read -n 1 -p "Möchtest du den Track \"$track_name\" aus deinen Liked Tracks entfernen? (y/n): " response
        echo ""  # Neue Zeile für saubere Ausgabe
        if [[ "$response" == "y" ]]; then
            remove_track_from_likes "$track_id"
            break
        elif [[ "$response" == "n" ]]; then
            echo "\"$track_name\" bleibt in deinen Liked Tracks."
            break
        else
            echo "Ungültige Eingabe. Bitte 'y' oder 'n' eingeben."
        fi
    done
}

# Entfernt einen Track aus den Liked Tracks
remove_track_from_likes() {
    local track_id=$1
    curl -s -X DELETE "https://api.spotify.com/v1/me/tracks?ids=$track_id" -H "Authorization: Bearer $ACCESS_TOKEN"
    echo "Track mit ID $track_id wurde aus den Liked Tracks entfernt."
}

# Hauptfunktion
main() {
    # Hole den Benutzerzugriffstoken
    get_new_access_token

    local offset=0
    local total=1  # Setze initial auf 1, um die Schleife zu starten

    while [ "$offset" -lt "$total" ]; do
        # Rufe die nächsten 50 Tracks ab
        liked_tracks=$(get_liked_tracks $offset)

        # Gesamte Anzahl der Tracks ermitteln
        total=$(echo "$liked_tracks" | jq -r '.total')

        # Anzahl der Tracks im aktuellen "page" (maximal 50)
        track_count=$(echo "$liked_tracks" | jq -r '.items | length')
        
        # Durchlaufe die Tracks in umgekehrter Reihenfolge (älteste zuerst)
        for ((i=track_count-1; i>=0; i--)); do
            track=$(echo "$liked_tracks" | jq -c ".items[$i]")

            track_id=$(echo "$track" | jq -r '.track.id')
            track_name=$(echo "$track" | jq -r '.track.name')

            # Trackdetails anzeigen
            show_track_details "$track"

            # Benutzer fragen, ob der Track entfernt werden soll
            ask_to_remove_track "$track_id" "$track_name"
        done

        # Erhöhe den Offset um 50, um die nächste "Page" von Tracks abzurufen
        offset=$((offset + 50))
    done
}

# Starte das Skript
main
