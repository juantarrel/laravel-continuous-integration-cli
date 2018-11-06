#!/usr/bin/env bash
# Deploy Script

####################################
#
# Configuration vars
#
####################################

# user
AWS_USER=
# enviroments
AWS_QA=
AWS_STAGE=
AWS_PRODUCTION=
# cert .pem
AWS_CERT=
# name project
NAME_PROJECT=
# repository
GIT_REPOSITORY="https://user:password@bitbucket.org/userowner/$NAME_PROJECT.git"
ENVIROMENT=0
# remote commands
REMOTE_COMMANDS=`cat remote-commands.sh`

echo "What enviroment do you want to deploy?"
echo "-- Select Number --"
echo -e "QA \t\t(1)"
echo -e "STAGE \t\t(2)"
echo -e "PRODUCTION \t(3)"
echo -e "EXIT \t\t(0)"
read ENVIROMENT

function listBranches {
    echo "Listing branches..."
    git clone $GIT_REPOSITORY>/dev/null
    cd $NAME_PROJECT
    git pull
    git branch -a
    cd ..
    rm -rf $NAME_PROJECT
}

function deploy {
    local ENV=""
    local ENV_NAME=""
    case $1 in
        1 )
            ENV=$AWS_QA
            ENV_NAME="QA"
            ;;
        2 )
            ENV=$AWS_STAGE
            ENV_NAME="STAGE"
            ;;
        3 )
            ENV=$AWS_PRODUCTION
            ENV_NAME="PRODUCTION"
            ;;
        * )
        exit 0
        ;;
    esac

    listBranches

    echo "Connecting to $ENV_NAME..."
    ssh -i $AWS_CERT -T $AWS_USER@$ENV << EOSSH
        echo $REMOTE_COMMANDS
        makeBackup $NAME_PROJECT
        pullProject $NAME_PROJECT $GIT_REPOSITORY
        echo -e "\033[0;32mThe enviroment $ENV_NAME is done !!!  check here -> http://$ENV\033[m"
EOSSH

}

deploy $ENVIROMENT

