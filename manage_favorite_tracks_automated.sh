#!/bin/bash

# Spotify API credentials
CLIENT_ID="ff681234610049e4bd94cde20442956b"
CLIENT_SECRET="" # removed
REDIRECT_URI="http://localhost:8888/callback"  # z.B. http://localhost:8888/callback
SCOPES="user-library-read user-library-modify"
TOKEN_URL="https://accounts.spotify.com/api/token"
LIKED_TRACKS_URL="https://api.spotify.com/v1/me/tracks"

# Funktion, um den OAuth-Link mit curl aufzurufen und den Auth-Code zu empfangen
start_auth_server() {
    AUTH_URL="https://accounts.spotify.com/authorize?client_id=$CLIENT_ID&response_type=code&redirect_uri=$REDIRECT_URI&scope=$SCOPES"
    
    echo "Öffne die OAuth-URL mit curl: $AUTH_URL"

    # Starte den Python-HTTP-Server im Hintergrund
    python3 -m http.server 8888 > server.log 2>&1 &
    SERVER_PID=$!

    sleep 2

    # Verwende curl, um den OAuth-Prozess zu starten, und folge allen Weiterleitungen
    curl -L "$AUTH_URL" -o /dev/null

    # Warte darauf, dass der Benutzer den Auth-Code eingibt (warte 30 Sekunden)
    sleep 30

    # Finde die Auth-Code-Anfrage in der Logdatei
    AUTH_CODE=$(grep "GET /callback?code=" server.log | sed -n 's/.*code=\([^&]*\).*/\1/p')

    # Beende den Python-Server
    kill $SERVER_PID
    rm server.log

    if [ -z "$AUTH_CODE" ]; then
        echo "Fehler beim Empfang des Auth-Codes."
        exit 1
    else
        echo "Empfangener Auth-Code: $AUTH_CODE"
    fi
}

# Funktion, um ein neues Access Token zu holen
get_new_access_token() {
    echo "Hole neues Access Token mit dem Auth-Code..."

    RESPONSE=$(curl -s -X POST "$TOKEN_URL" \
        -H "Authorization: Basic $(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)" \
        -d grant_type=authorization_code \
        -d code="$AUTH_CODE" \
        -d redirect_uri="$REDIRECT_URI")

    ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
    REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh_token')

    if [ "$ACCESS_TOKEN" == "null" ]; then
        echo "Fehler beim Abrufen des Access-Tokens"
        exit 1
    else
        echo "Access Token: $ACCESS_TOKEN"
        echo "Refresh Token: $REFRESH_TOKEN"
    fi
}

# Funktion, um alle Liked Tracks zu holen
fetch_liked_tracks() {
    echo "Rufe alle Liked Tracks ab..."

    # Hole alle Liked Tracks und sortiere nach ältesten zuerst
    TRACKS=$(curl -s -X GET "$LIKED_TRACKS_URL?limit=50&offset=$1" \
        -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.items | reverse')

    # Zeige jeden Track und frage, ob er gelöscht werden soll
    echo "$TRACKS" | jq -c '.[]' | while read -r track; do
        TRACK_NAME=$(echo "$track" | jq -r '.track.name')
        ARTIST_NAME=$(echo "$track" | jq -r '.track.artists[0].name')
        TRACK_ID=$(echo "$track" | jq -r '.track.id')

        echo "Track: $TRACK_NAME - Artist: $ARTIST_NAME"
        echo -n "Möchtest du diesen Track löschen? (y/n): "
        read -n 1 answer
        echo
        if [ "$answer" == "y" ]; then
            delete_liked_track "$TRACK_ID"
        fi
    done
}

# Funktion, um einen Track zu löschen
delete_liked_track() {
    TRACK_ID=$1
    echo "Lösche Track mit ID: $TRACK_ID"

    RESPONSE=$(curl -s -X DELETE "$LIKED_TRACKS_URL?ids=$TRACK_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN")

    if [ "$RESPONSE" == "" ]; then
        echo "Track erfolgreich gelöscht."
    else
        echo "Fehler beim Löschen des Tracks."
    fi
}

# Hauptablauf
start_auth_server
get_new_access_token

# Spotify liked tracks abfragen und löschen
OFFSET=0
while true; do
    fetch_liked_tracks $OFFSET
    OFFSET=$((OFFSET + 50))
    echo -n "Weitere 50 Tracks laden? (y/n): "
    read -n 1 answer
    echo
    if [ "$answer" != "y" ]; then
        break
    fi
done
