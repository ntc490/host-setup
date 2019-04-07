#!/bin/bash

if [ "$REPO_ROOT" == "" ]; then
	REPO_ROOT=$(pwd)/..
fi

ln -s $REPO_ROOT/wallpaper $HOME/Wallpaper
