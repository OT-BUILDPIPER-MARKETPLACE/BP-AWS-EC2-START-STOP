#!/bin/bash

function switchBranch() {
    TGT_BRANCH="$1"

    git checkout "$TGT_BRANCH"
}

function showStatusInShortFormat() {
    git status -s
}

function findConflictingFiles() {
    SRC_BRANCH="$1"
    TGT_BRANCH="$2"

    git checkout -q "${TGT_BRANCH}"
    # git pull origin "${TGT_BRANCH}"

    git checkout -q -b temp_merge_branch
    git merge -q "$SRC_BRANCH" 1> /dev/null

    conflicts=$(git diff --name-only --diff-filter=U)
    git merge --abort
    git checkout -q "${TGT_BRANCH}"
    git branch -q -D temp_merge_branch
    echo "$conflicts"
}

function getLastAuthorOfFile() {
    BRANCH="$1"
    FILE="$2"

    git checkout -q "$BRANCH"

    git log -1 --pretty=format:"%an" "${FILE}"
}

function getLastAuthorOfFiles() {
    BRANCH="$1"
    FILES="$2"
    for FILE in "${FILES[@]}"
    do
        author=$(getLastAuthorOfFile "$BRANCH" "$FILE")
        echo "${FILE}: ${author}"
    done
}
