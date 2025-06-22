#!/bin/bash

function isFileExist() {
    FILEPATH="$1"

    if [ -f "$FILEPATH" ]; then
        echo 0
    else
        echo 1
    fi
}

function fileContainsString() {
    FILEPATH="$1"
    TEXT="$2"
    grep -q "${TEXT}" "${FILEPATH}"
    echo $?
}

function getLineForAString() {
    FILEPATH="$1"
    TEXT="$2"
    grep "${TEXT}" "${FILEPATH}" 
}

function textExistsInALine(){
    LINE="$1"
    TEXT="$2"
    echo "${LINE}"  | grep -q "${TEXT}"
    echo "$?"
}