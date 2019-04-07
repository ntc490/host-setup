#!/bin/bash

if [ "$REPO_ROOT" == "" ]; then
	REPO_ROOT=$(pwd)/..
fi

echo "Update package cache..."
sudo pacman -Syy

echo "Adding a few packages..."
sudo pacman -S emacs
