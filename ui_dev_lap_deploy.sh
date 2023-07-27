#!/bin/bash

echo "UI DEV Deployment"

deploy () {

    echo "Copying $filename to ./resourceDev/ui-zip-builds/lap/"
    cp $filename ./resourceDev/ui-zip-builds/lap/

    echo "Renaming $filename to current_lap.zip"
    if ! mv $filename current_lap.zip; then
        echo "Failed to rename $filename to current_lap.zip"
        exit 1
    fi

    echo "Moving current_lap.zip to $nginx_dir"
    mv current_lap.zip $nginx_dir

    cd $nginx_dir;
    echo "Inside $nginx_dir directory"

    echo "Creating directory dev_lap_new/ui"
    mkdir -p dev_lap_new/ui

    echo "Moving current_lap.zip to dev_lap_new/ui"
    mv current_lap.zip dev_lap_new/ui
    
    cd dev_lap_new/ui; 
    echo "Inside dev_lap_new/ui directory"

    echo "Unzipping current_lap.zip"
    # if ! unzip current_lap.zip; then
    #     echo "ERROR: Failed to unzip current_lap.zip"
    #     exit 1
    # fi

    if ! rm -rf current_lap.zip; then
        echo "ERROR: Failed to remove current_lap.zip"
    fi 

    cd $nginx_dir
    echo "Listing files in $nginx_dir"
    ls

    current=dev
    backup=$(ls | grep "dev_lap_v" | sort -V | tail -n 1)

    lastest_backup=""

    if [ $backup ]
    then
        echo "Previous backup found: $backup"
        backup_no=${backup:9}
        backup_no=$((backup_no + 1))
        lastest_backup="dev_lap_v$backup_no"
    else
        echo "No Previous Backup found"
        lastest_backup="dev_lap_v1"
    fi

    echo "Changing into dev and Renaming lap to $lastest_backup"
    cd $current # dev
    if ! mv lap ../$lastest_backup; then
        echo "Failed to rename lap to $lastest_backup"
        exit 1
    fi

    ls ../
    echo "Current Backup is at $lastest_backup"

    echo "Renaming dev_lap_new to lap"
    if ! mv ../dev_lap_new lap; then
        echo "Failed to rename dev_lap_new to lap"
        exit 1
    fi

    echo "Changing directory permission"
    find . -type d -exec chmod 755 {} \; 

    cd lap/ui
    echo "Inside lap/ui directory"

    echo "Changing file permission"
    find . -type f -exec chmod 644 {} \; 

    if ! systemctl restart nginx; then
        echo "ERROR: Failed to restart nginx"
        exit 1
    fi

    if ! systemctl status nginx; then
        echo "ERROR: Failed to check nginx status"
        exit 1
    fi

    echo "Deployment Done."
}

pattern='^DEV_LAP_[0-9]{8}_V[0-9]+\.zip$'

nginx_dir="/usr/share/nginx/html"

echo "The available .zip files are:"
ls | grep ".zip"

while true; do
    read -p 'Enter the name of the file to deploy: ' filename
    echo "The selected file is: $filename"

    if [[ "$filename" =~ $pattern ]];
    then
    echo "File name $filename is in the correct format."
        file=$(ls | grep $filename)
        if [ $file ]
        then
            echo "File $filename selected for deployment"
            break
        else
            echo "File $filename does not exist"
            echo "The available .zip files are:"
            ls | grep ".zip"
        fi

    else
        echo "File name $filename is not in the correct format. It should be in the format DEV_LAP_DDMMYYYY_VX.zip"
    fi
done

echo "Deployment Started.."

# Calling deploy function
deploy