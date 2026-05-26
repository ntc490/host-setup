#!/usr/bin/env bash
# Docker engine, enabled service, and current user in the docker group.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs docker

log "Enabling docker.service"
sudo systemctl enable --now docker.service

if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    log "$USER already in docker group"
else
    log "Adding $USER to docker group (log out/in for it to take effect)"
    sudo usermod -aG docker "$USER"
fi
