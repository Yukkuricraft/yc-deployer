#!/bin/bash

# This script just updates the git repos - it does NOT handle restarting containers.

ORG_NAME_TO_DEPLOY="${ORG_NAME_TO_DEPLOY:-NONE}"
REPO_NAME_TO_DEPLOY="${REPO_NAME_TO_DEPLOY:-NONE}"
TARGET_HOST="${TARGET_HOST:-NONE}"
TARGET_PORT="${TARGET_PORT:-NONE}"
TARGET_USER="${TARGET_USER:-NONE}"

if [[ x"$ORG_NAME_TO_DEPLOY" == x"NONE" ]]; then
  echo "Expected env var ORG_NAME_TO_DEPLOY to be set but was not! Aborting."
  exit 1
fi

if [[ x"$REPO_NAME_TO_DEPLOY" == x"NONE" ]]; then
  echo "Expected env var REPO_NAME_TO_DEPLOY to be set but was not! Aborting."
  exit 1
fi

if [[ x"$TARGET_HOST" == x"NONE" ]]; then
  echo "Expected env var TARGET_HOST to be set but was not! Aborting."
  exit 1
fi

if [[ x"$TARGET_PORT" == x"NONE" ]]; then
  echo "Expected env var TARGET_PORT to be set but was not! Aborting."
  exit 1
fi

if [[ x"$TARGET_USER" == x"NONE" ]]; then
  echo "Expected env var TARGET_USER to be set but was not! Aborting."
  exit 1
fi

grep "$TARGET_HOST]:$TARGET_PORT" ~/.ssh/known_hosts > /dev/null
if [[ "$?" != "0" ]]; then
    ssh-keyscan -p $TARGET_PORT $TARGET_HOST >> ~/.ssh/known_hosts
fi

ssh $TARGET_USER@$TARGET_HOST -p $TARGET_PORT << SCRIPT
pwd

function log {
  echo ""
  echo ">> \$@"
}

log "Ensuring github.com is in known_hosts"
grep "github.com" .ssh/known_hosts
if [[ "$?" != "0" ]]; then
    ssh-keyscan github.com >> .ssh/known_hosts
fi

log "Ensuring org directory exists"
mkdir -p $ORG_NAME_TO_DEPLOY
cd $ORG_NAME_TO_DEPLOY

if [[ ! -d "$REPO_NAME_TO_DEPLOY" ]]; then
    log "Detected first time deployment - cloning repo"
    # First time deployment
    git clone git@github.com:${ORG_NAME_TO_DEPLOY}/${REPO_NAME_TO_DEPLOY}.git
    cd $REPO_NAME_TO_DEPLOY

    log "Initializing git submodules"
    git submodule init

    log "Updating git submodules"
    git submodule update

else
    log "Repo already exists - cd'ing in"
    # Repo already exists, just pull
    cd $REPO_NAME_TO_DEPLOY

    log "Blowing away local changes"
    # Do we want to assume and blow away any local changes every time? Probably?
    git reset HEAD --hard

    log "Git rebase pulling"
    # We shouldn't need to rebase if there aren't any local changes but uh... I guess to
    # account for potential "quick fix" local commits?
    git pull --rebase
fi

log "Done"
SCRIPT
