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
# remote commands @TODO its works but need refactor
REMOTE_COMMANDS=`cat remote-commands.sh | awk '{print $0, "\nif [[ $? -gt 0 ]]; then\n echo \"\033[0;31mThe is an error\033[m\"\nreturn 1\n fi"}'`

BRANCH_TO_DEPLOY=""
echo "What enviroment do you want to deploy?"
echo "-- Select Number --"
echo -e "QA \t\t(1)"
echo -e "STAGE \t\t(2)"
echo -e "PRODUCTION \t(3)"
echo -e "EXIT \t\t(0)"
read ENVIROMENT

function listBranches {
    echo "Listing branches..."
    if ! [ -d $NAME_PROJECT ]; then
        git clone $GIT_REPOSITORY &>/dev/null
    fi

    cd $NAME_PROJECT
    git pull>/dev/null
    git branch -av | awk 'BEGIN {FS=" "} {gsub("*|refs/heads/|remotes/origin/", "")} {print $1}' > branches_clean.txt
    sort -u branches_clean.txt > branches_uniques.txt
    readarray BRANCHES_ARRAY < branches_uniques.txt

    # for branches array
    echo "-- Select branch to deploy to $1 --"
    for (( i=1; i<${#BRANCHES_ARRAY[@]}+1; i++ ));
    do
      echo -e ${BRANCHES_ARRAY[$i-1]} "\t\t" "($i)"
    done
    read SELECTED_ARRAY_BRANCH
    BRANCH_TO_DEPLOY=${BRANCHES_ARRAY[SELECTED_ARRAY_BRANCH-1]}
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

    listBranches $ENV_NAME

    echo "Connecting to $ENV_NAME..."
    ssh -i $AWS_CERT -T $AWS_USER@$ENV << EOSSH
        echo $REMOTE_COMMANDS
        makeBackup $NAME_PROJECT
        pullProject $NAME_PROJECT $GIT_REPOSITORY $BRANCH_TO_DEPLOY
EOSSH

    if [[ $? -eq 0 ]]; then
        echo -e "\033[0;32mThe enviroment $ENV_NAME is done !!!  check here -> http://$ENV\033[m"
        return 0
    fi

}

deploy $ENVIROMENT

