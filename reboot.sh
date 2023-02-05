#!/bin/bash

FREEBOX_URL="https://212.27.38.253"
HTTPIE_OPTS="--verify no"
APP_ID="fr.freebox.reboot"
APP_NAME="reboot"
APP_VERSION="0.0.1"
APP_TOKEN=
APP_STATUS='pending'
SESSION_TOKEN=

request_app_token() {
    APP_RESULT=$(http $HTTPIE_OPTS POST $FREEBOX_URL/api/v4/login/authorize/ app_id="$APP_ID" app_name="$APP_NAME" app_version="$APP_VERSION" device_name="$(hostname)")
    APP_TOKEN=$(echo $APP_RESULT | jq -r .result.app_token)
    TRACK_ID=$(echo $APP_RESULT | jq -r .result.track_id)
}

check_app_status() {
    echo "Avez-vous validé depuis la freebox l'autorisation (flèche de droite)? - appuyer sur une touche pour continuer."
    echo "Premi il tasto sulla Iliadbox per autorizzare (freccia a destra) - premi invio per continuare."
    read
    echo "Penser à donner le droit de 'Modification des réglages de la Freebox' pour permettre le reboot - appuyer sur une touche pour continuer."
    echo "Dai il permesso di 'Modifica delle impostazioni della iliadbox' per consentire il reboot - premi invio per continuare."
    read

    while [[ "$APP_STATUS" == 'pending' ]]; do
        sleep 5
        APP_STATUS=$(http $HTTPIE_OPTS $FREEBOX_URL/api/v4/login/authorize/$TRACK_ID | jq -r .result.status)
        echo "status => $APP_STATUS"
    done
}

store_app_token() {
    echo "APP_TOKEN=$APP_TOKEN"
    echo "APP_TOKEN=$APP_TOKEN" > $HOME/.reboot_freebox
}

request_a_session() {
    CHALLENGE=$(http $HTTPIE_OPTS $FREEBOX_URL/api/v4/login | jq -r .result.challenge)
    PASSWORD=$(echo -n $CHALLENGE | openssl dgst -sha1 -hmac "$APP_TOKEN" -binary | xxd -p)
    RESULT=$(http $HTTPIE_OPTS $FREEBOX_URL/api/v4/login/session app_id="$APP_ID" password="$PASSWORD")
    SESSION_TOKEN=$(echo $RESULT | jq -r .result.session_token)
}

request_reboot_and_exit() {
    echo "Tentative de reboot."
    RESULT=$(http $HTTPIE_OPTS POST $FREEBOX_URL/api/v4/system/reboot X-Fbx-App-Auth:$SESSION_TOKEN | jq -r .success)
    if [[ $RESULT == 0 ]]; then
        echo "La freebox reboot."
        exit 0
    else
        exit 100
    fi
}

### main
if [[ -f "$HOME/.reboot_freebox" ]]; then
    source $HOME/.reboot_freebox
    request_a_session
    request_reboot_and_exit
else
    request_app_token
    check_app_status
    store_app_token
    echo "Initialisation terminée, relancer le script pour rebooter la freebox."
    echo "Inizializzazione completa, rilancia lo script per riavviare la iliadbox."
fi

