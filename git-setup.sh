#!/bin/bash

if [ "$REPO_ROOT" == "" ]; then
	REPO_ROOT=$(pwd)/..
fi

echo "Set git ID..."
git config --global user.email "nathan_crapo@yahoo.com"
git config --global user.name "Nathan Crapo"

echo "Setting up git aliases..."
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
