#!/bin/bash
#
# Entrypoint script for YIO remote-os build
#

set -e

YIO_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#=============================================================

GitProjects=(
    "https://github.com/YIO-Remote/integration.dock.git,dev"
    "https://github.com/YIO-Remote/integration.homey.git,dev"
    "https://github.com/YIO-Remote/integration.home-assistant.git,dev"
    "https://github.com/YIO-Remote/integration.ir.git,dev"
    "https://github.com/YIO-Remote/integration.openhab.git,dev"
    "https://github.com/YIO-Remote/remote-os.git,dev"
    "https://github.com/YIO-Remote/remote-software.git,dev"
    "https://github.com/YIO-Remote/web-configurator.git,master"
)

QtIntegrationProjects=(
    integration.dock
    integration.ir
    integration.home-assistant
    integration.homey
)

#=============================================================

usage() {
  cat << EOF

YIO Remote project utility.

Commands:
info     Print Git information of the available projects
init     Initialize build: checkout all projects & prepare buildroot
update   Update all repositories on the current branch (git pull)
git [options] <command> [<args>] Perform Git command on all projects

<project> git [options] <command> [<args>]
                  Perform Git command on given project

EOF
}

header() {
    echo "--------------------------------------------------------------------------------"
    echo $1
    echo "--------------------------------------------------------------------------------"
}

#=============================================================

gitInfo() {
    cd "${YIO_SRC}/$1"
    if [ -d ".git" ]; then
        printf "%-30s %-30s %s\n" $1 $(git rev-parse --abbrev-ref HEAD) $(git log --pretty=format:'%h' -n 1)
    fi
}

#=============================================================

projectInfo() {
    subdircount=`find "${YIO_SRC}" -maxdepth 1 -type d | wc -l`
    if [ $subdircount -lt 2 ]
    then
        echo "No projects found. Run 'init' first to clone Git projects"
        exit 1
    fi
    echo ""
    echo "Git information:"
    cd "${YIO_SRC}"
    for D in */; do
        gitInfo "$D"
    done
    echo ""
    # TODO print docker build image information
}

#=============================================================

checkoutProject() {
    name="${1##*/}"
    projectName="${name%.*}"

    if [ ! -d "${YIO_SRC}/${projectName}" ]; then
        header "Git clone $1"
        cd "${YIO_SRC}"
        git clone $1
        cd ${projectName}
        git checkout $2
    fi
}

checkoutProjects() {
    for item in ${GitProjects[*]}; do
        PROJECT=$(awk -F, '{print $1}' <<< $item)
        BRANCH=$(awk -F, '{print $2}' <<< $item)
        checkoutProject $PROJECT $BRANCH
    done
}

#=============================================================

gitCommandAll() {
    subdircount=`find "${YIO_SRC}" -maxdepth 1 -type d | wc -l`
    if [ $subdircount -lt 2 ]
    then
        echo "No projects found. Run 'init' first to clone Git projects"
        return
    fi
    cd "${YIO_SRC}"
    echo ""
    for D in */; do
        if [ -d "${YIO_SRC}/${D}/.git" ]; then
            cd "${YIO_SRC}/${D}"
            printf "%-20s: 'git %s" $D
            echo "$@'" 
            git $@
        fi
    done
}

#=============================================================

checkProjectExists() {
    if [ ! -d "${YIO_SRC}/${1}" ]; then
        echo "ERROR: Project $1 doesn't exist"
        exit 1
    fi
}

#=============================================================

initRemoteOS() {
    header "Initializing Buildroot project in remote-os..."

    checkProjectExists remote-os

    cd "${YIO_SRC}/remote-os"
    git submodule init
    git submodule update
}

#=============================================================

initialize() {
    checkoutProjects
    initRemoteOS
}


#=============================================================
# Script starts here
#=============================================================
if [ -z "$YIO_SRC" ]; then 
    echo "Environment variable YIO_SRC not defined! Value must point to root folder of YIO remote project repositories."
    exit 1
fi

if [ $# -eq 1 ]; then
    # handle single command
    if [ "$1" = "help" ] || [ "$1" = "-h" ]; then
        usage
    elif [ "$1" = "info" ]; then
        projectInfo
    elif [ "$1" = "init" ]; then
        initialize
    elif [ "$1" = "update" ]; then
        gitCommandAll pull
    else
        echo "ERROR: Invalid command given, exiting!"
        exit 1
    fi
elif [ "$1" = "git" ]; then
    gitCommandAll ${@:2}
elif [ "$2" = "git" ] && (( $# > 2 )); then
    checkProjectExists $1
    cd "${YIO_SRC}/${1}"
    ${@:2}
else
    usage;
    echo "No command given, exiting!"
    exit 1
fi
