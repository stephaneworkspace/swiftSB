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

# Filtrer les fichiers .sha256 et les vérifier un par un
grep '\.sha256$' files_to_check.txt | while read sha256_file; do
    echo "Traitement de $sha256_file..."

    # Télécharger le fichier .sha256
    swift download $CONTAINER_NAME "$sha256_file" --output "$sha256_file"

    # Extrait le nom du fichier réel à partir du nom du fichier .sha256
    actual_file="${sha256_file%.sha256}"

    # Télécharger le fichier correspondant
    swift download $CONTAINER_NAME "$actual_file" --output "$actual_file"

    # Calculer le checksum SHA-256 du fichier téléchargé
    calculated_checksum=$(sha256sum "$actual_file" | awk '{print $1}')

    # Lire le checksum attendu à partir du fichier .sha256
    expected_checksum=$(cat "$sha256_file")

    # Comparer les checksums
    if [[ "$calculated_checksum" == "$expected_checksum" ]]; then
        echo "$actual_file: SUCCESS"
    else
        echo "$actual_file: CHECKSUM MISMATCH"
    fi

    # Supprimer les fichiers téléchargés pour économiser de l'espace disque
    rm "$sha256_file"
    rm "$actual_file"

done

echo "Checksum verification completed."
