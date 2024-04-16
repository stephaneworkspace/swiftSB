#!/bin/bash
#pip install python-swiftclient
#pip install python-keystoneclient
#export OS_AUTH_URL="https://swiss-backup02.infomaniak.com/identity/v3"
#export OS_PROJECT_NAME="sb_project_SBI-****"
#export OS_USER_DOMAIN_NAME="default"
#export OS_PROJECT_DOMAIN_NAME="default"
#export OS_USERNAME="SBI-****"
#export OS_PASSWORD="*****"
#export OS_REGION_NAME="RegionOne"
#export OS_IDENTITY_API_VERSION="3"
#swift list

## Configuration
CONTAINER_NAME="default"
DIRECTORY_NAME="MAO_001"

# Créer un fichier temporaire pour stocker la liste des fichiers
swift list $CONTAINER_NAME --prefix $DIRECTORY_NAME > files_to_check.txt

grep '\.sha256$' files_to_check.txt | while read sha256_file; do
    echo "Traitement de $sha256_file..."

    # Préparer les chemins locaux pour le téléchargement
    sha256_file_path="temp_downloads/$sha256_file"
    mkdir -p "$(dirname "$sha256_file_path")"

    # Télécharger le fichier .sha256
    swift download $CONTAINER_NAME --output "$sha256_file_path" "$sha256_file"

    # Extraire le nom du fichier réel et son chemin à partir du nom du fichier .sha256
    actual_file_path="temp_downloads/${sha256_file%.sha256}"

    # Télécharger le fichier correspondant
    swift download $CONTAINER_NAME --output "$actual_file_path" "${sha256_file%.sha256}"

    # Calculer le checksum SHA-256 du fichier téléchargé
    calculated_checksum=$(sha256sum "$actual_file_path" | awk '{print $1}')

    # Lire le checksum attendu à partir du fichier .sha256
    expected_checksum=$(cat "$sha256_file_path")

    # Comparer les checksums
    if [[ "$calculated_checksum" == "$expected_checksum" ]]; then
        echo "$actual_file_path: SUCCESS"
    else
        echo "$actual_file_path: CHECKSUM MISMATCH"
    fi

    # Supprimer les fichiers téléchargés pour économiser de l'espace disque
    rm "$sha256_file_path"
    rm "$actual_file_path"
done

echo "Checksum verification completed."
