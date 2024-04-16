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

CONTAINER_NAME="default"
DIRECTORY_NAME="MAO_001"

swift list $CONTAINER_NAME --prefix $DIRECTORY_NAME/ > files_to_check.txt

grep '\.sha256$' files_to_check.txt | while read sha256_file; do
    echo "Traitement de $sha256_file..."

    sha256_file_path="temp_downloads/$sha256_file"
    actual_file_path="temp_downloads/${sha256_file%.sha256}"
    

    if [ -d "$directory_path" ]; then
        rm -rf "$directory_path"
    fi
    mkdir -p "$(dirname "$sha256_file_path")"

    # swift download $CONTAINER_NAME --output "$sha256_file_path" "$sha256_file"
    swift download $CONTAINER_NAME "$sha256_file" --output - | pv > "$sha256_file_path"

    # swift download $CONTAINER_NAME --output "$actual_file_path" "${sha256_file%.sha256}"
    swift download $CONTAINER_NAME  "${sha256_file%.sha256}" --output - | pv > "$actual_file_path"

    pushd "$(dirname "$actual_file_path")"
    if shasum -a 256 -c "$(basename "$sha256_file_path")"; then
    #    echo -e "\e[32m$(basename "$sha256_file_path"): SUCCESS\e[0m"
         echo "$(tput setaf 2)$(basename "$sha256_file_path"): SUCCESS$(tput sgr0)"
    else
    #    echo -e "\e[31m$(basename "$sha256_file_path"): CHECKSUM MISMATCH\e[0m"
         echo "$(tput setaf 1)$(basename "$sha256_file_path"): CHECKSUM MISMATCH$(tput sgr0)"
    fi
    popd


    rm "$sha256_file_path"
    rm "$actual_file_path"
done

echo "Checksum verification completed."
