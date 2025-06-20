#!/bin/bash
set -euo pipefail

ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
GREEN="${ESC}[32m"
CYAN="${ESC}[36m"

REPO_USERNAME='night-play-925'
REPONAME='dotfiles'

REPO_ROOT_DIR=${HOME}/work/git/${REPONAME}
IGNORE_PATHS=".git .gitmodules .github .idea docs darwin linux root scripts dotfiles.init.d LICENSE README.md"

function main() {
    # Clone or pull repo
    echoH1 "Clone or pull github.com/${REPO_USERNAME}/${REPONAME}"
    mkdir -pv "$REPO_ROOT_DIR"
    if [[ ! -e "${REPO_ROOT_DIR}/.git" ]]; then
        git clone "git@github.com:${REPO_USERNAME}/${REPONAME}.git" "$REPO_ROOT_DIR"
    else
        cd "$REPO_ROOT_DIR"
        git pull
    fi
    
    # Guard unsupported OS
    OS_NAME="$(uname -s | awk '{print tolower($0)}')"
    if [[ "${OS_NAME}" != 'darwin' && "${OS_NAME}" != 'linux' ]]; then
        echo "$OS_NAME is not supported."
        exit 1
    fi

    # Define global vars
    SUBMODULE_DIRS=$(git submodule status -- . 2>&1 | cut -d ' ' -f 3)

    # Generate symlinks
    echoH1 'Install common configuration files'
    genSymlinks ${REPO_ROOT_DIR} ${HOME}

    echoH1 "Install common system configuration files"
    genSymlinks "${REPO_ROOT_DIR}/root" "" 1

    echoH1 "Install ${OS_NAME} configuration files"
    genSymlinks "${REPO_ROOT_DIR}/${OS_NAME}" "${HOME}"

    echoH1 "Install ${OS_NAME} system configuration files"
    genSymlinks "${REPO_ROOT_DIR}/${OS_NAME}/root" "" 1

    # Run initialize scripts
    echoH1 'Run common initialization scripts'
    runScripts ${REPO_ROOT_DIR}/dotfiles.init.d

    echoH1 "Run ${OS_NAME} initialization scripts"
    runScripts ${REPO_ROOT_DIR}/${OS_NAME}/dotfiles.init.d

    # Done
    echoH1 'All tasks are done 🎉'
}

# Create symlinks recursively
function genSymlinks() {
    local SRC_DIR=$1
    local DST_DIR=$2
    local ACT_AS_ROOT=${3:+x}
    local MKDIR_BIN="${ACT_AS_ROOT:+sudo }mkdir"
    local LN_BIN="${ACT_AS_ROOT:+sudo }ln"

    if [[ ! -e ${SRC_DIR} ]]; then
        echo "No file to run"
        return 0
    fi

    local DOT_PATHS=$(ls -A ${SRC_DIR})
    for DOT_PATH in $DOT_PATHS; do
        local SRC_PATH="${SRC_DIR}/${DOT_PATH}"
        local DST_PATH="${DST_DIR}/${DOT_PATH}"

        # if it should be ignored, ignore it
        for IGNORE in $IGNORE_PATHS; do
            if [[ "${SRC_DIR}/${IGNORE}" = "${SRC_PATH}" ]]; then
                # continue outer `for` loop
                continue 2
            fi
        done

        # If source is directory, make it
        if [ -d "${SRC_PATH}" ]; then
            # If source is git submodule, create it as symlink
            for SUBMODULE in ${SUBMODULE_DIRS}; do
                if [[ "${REPO_ROOT_DIR}/${SUBMODULE}" =  "${SRC_PATH}" ]]; then
                    echo 'submodule detected. make symlink'
                    echoH2 "${LN_BIN} -s ${SRC_PATH} ${DST_PATH}"
                    if [[ -L "$DST_PATH" ]]; then
                        echo 'symlink exists. skipped'
                        continue 2
                    fi
                    ${LN_BIN} -s "${SRC_PATH}" "${DST_PATH}"
                
                    continue 2
                fi
            done

            echoH2 "${MKDIR_BIN} $DST_PATH"
            if [[ -e $DST_PATH ]]; then
                echo 'directory exists. skipped'
            else
                ${MKDIR_BIN} -p "${DST_PATH}"
            fi

            genSymlinks "${SRC_PATH}" "${DST_PATH}" "${ACT_AS_ROOT}"
            continue
        fi

        # If source is file, create it as symlink
        if [[ -f "${SRC_PATH}" ]]; then
            echoH2 "${LN_BIN} -s ${SRC_PATH} ${DST_PATH}"
            if [[ -e "$DST_PATH" ]]; then
                echo 'symlink exists. skipped'
                continue
            fi
            ${LN_BIN} -s "${SRC_PATH}" "${DST_PATH}"
        fi
    done
}
