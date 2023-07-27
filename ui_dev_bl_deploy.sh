#!/bin/bash

echo "UI DEV Deployment"

deploy () {

    echo "Copying $filename to ./resourceDev/ui-zip-builds/"
    cp $filename ./resourceDev/ui-zip-builds/

    echo "Renaming $filename to current.zip"
    if ! mv $filename current.zip; then
        echo "Failed to rename $filename to current.zip"
        exit 1
    fi

    echo "Moving current.zip to $nginx_dir"
    mv current.zip $nginx_dir

    cd $nginx_dir;
    echo "Inside $nginx_dir directory"

    echo "Creating directory dev_bl_new/ui"
    mkdir -p dev_bl_new/ui

    echo "Moving current.zip to dev_bl_new/ui"
    mv current.zip dev_bl_new/ui
    
    cd dev_bl_new/ui; 
    echo "Inside dev_bl_new/ui directory"

    echo "Unzipping current.zip"
    # if ! unzip current.zip; then
    #     echo "ERROR: Failed to unzip current.zip"
    #     exit 1
    # fi

    if ! rm -rf current.zip; then
        echo "ERROR: Failed to remove current.zip"
    fi 

    cd $nginx_dir
    echo "Listing files in $nginx_dir"
    ls

    current=dev
    backup=$(ls | grep "dev_v" | sort -V | tail -n 1)

    lastest_backup=""

    if [ $backup ]
    then
        echo "Previous backup found: $backup"
        backup_no=${backup:5}
        backup_no=$((backup_no + 1))
        lastest_backup="dev_v$backup_no"
    else
        echo "No Previous Backup found"
        lastest_backup="dev_v1"
    fi

    echo "Changing into dev and Renaming bl to $lastest_backup"
    cd $current # dev
    if ! mv bl ../$lastest_backup; then
        echo "Failed to rename bl to $lastest_backup"
        exit 1
    fi

    ls ../
    echo "Current Backup is at $lastest_backup"

    echo "Renaming dev_bl_new to bl"
    if ! mv ../dev_bl_new bl; then
        echo "Failed to rename dev_bl_new to bl"
        exit 1
    fi

    echo "Changing directory permission"
    find . -type d -exec chmod 755 {} \; 

    cd bl/ui
    echo "Inside bl/ui directory"

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

pattern='^DEV_[0-9]{8}_V[0-9]+\.zip$'

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
        echo "File name $filename is not in the correct format. It should be in the format DEV_DDMMYYYY_VX.zip"
    fi
done

echo "Deployment Started.."

# Calling deploy function
deploy