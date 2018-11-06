#!/usr/bin/env bash

function makeBackup {

    NAME_PROJECT=$1
    echo -e "\033[0;32mConnected\033[m"
    if ! [ -d "Backups" ]; then
        mkdir Backups
        echo -e "\033[0;32mBackups folder created\033[m"
    fi

    echo "Creating backup for current project..."
    cp -rf `echo "~/Projects/$NAME_PROJECT"` Backups
    cd Backups

    if [ -d "$NAME_PROJECT/vendor" ]; then
        rm -rf $NAME_PROJECT/vendor
        echo -e "\033[0;32mVendor deleted\033[m"
    fi

    if [ -d "$NAME_PROJECT/node_modules" ]; then
        rm -rf $NAME_PROJECT/node_modules
        echo -e "\033[0;32mNode modules deleted\033[m"
    fi

    tar -zcvf `echo "$(date "+%Y-%m-%d-%H-%M-%S").tar.gz"` `echo "$NAME_PROJECT"`>/dev/null
    rm -rf $NAME_PROJECT
    echo -e "\033[0;32mBackup created\033[m"
}

function pullProject {
    echo "Pulling branch to project..."

    if [ -d ~/Projects/$1 ]; then
        if [ -f ~/Projects/$1/.env ]; then
            cp ~/Projects/$1/.env ~/Projects/
        fi
        rm -r ~/Projects/$1
    fi

    echo "Cloning repository"
    cd ~/Projects
    git clone $2
    echo -e "\033[0;32mRepository cloned\033[m"

    cd $1

    git checkout $3

    if [ -f ~/Projects/.env ]; then
        cp ~/Projects/.env ~/Projects/$1/
    fi

    echo "Removing git files..."
    sudo rm -rf .git*
    sudo rm .env.example
    sudo rm README.md

    echo "Installing dependencies.."
    composer install


    php artisan key:generate
    echo "Migrations..."
    php artisan migrate

    echo -e "\033[0;32mBackend ready\033[m"
    npm i
    echo -e "\033[0;32mFrontend ready\033[m"

    # @TODO change permissions
    echo "Setting permissions"
    sudo chmod 777 -R ~/Projects/$1/storage/
    sudo chmod 777 -R ~/Projects/$1/bootstrap/
    echo -e "\033[0;32mPermissions ready\033[m"
}
