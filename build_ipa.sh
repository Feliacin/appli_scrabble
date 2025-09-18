#!/bin/bash
set -e

# Définir les chemins
APP_NAME="Runner.app"
BUILD_PATH="build/ios/iphoneos"
IPA_NAME="Runner.ipa"

# Nettoyage de l'ancien build
rm -rf Payload
rm -f $IPA_NAME

# Création du dossier Payload et déplacement du fichier .app
mkdir Payload
cp -R "$BUILD_PATH/$APP_NAME" Payload/

# Compression en .ipa
zip -r $IPA_NAME Payload

echo "✅ Fichier $IPA_NAME créé avec succès !"

