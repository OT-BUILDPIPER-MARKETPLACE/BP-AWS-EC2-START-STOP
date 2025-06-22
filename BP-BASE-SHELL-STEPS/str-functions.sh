#!/bin/bash

function isStrNonEmpty() {
    STR="$1"
    if [ -z "$STR" ]; then
        echo 1
    else
        echo 0
    fi
}

function getNthTextInALine() {
    LINE="$1"
    SEPARATOR="$2"
    POSITION="$3"

    echo "${LINE}" | awk -F "${SEPARATOR}" -v POS="${POSITION}" "{print $POS}"
}
