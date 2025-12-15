#!/bin/bash
# Docker-in-Docker initialization script
# Based on devcontainers/features docker-in-docker

set -e

# Only run if DIND_ENABLED is set
if [[ "$DIND_ENABLED" != "true" ]]; then
    exit 0
fi

# Clean up any stale PID files
sudo rm -f /var/run/docker.pid /var/run/containerd/containerd.pid 2>/dev/null || true

# Mount security filesystem if not already mounted (for AppArmor)
if ! mountpoint -q /sys/kernel/security 2>/dev/null; then
    sudo mount -t securityfs none /sys/kernel/security 2>/dev/null || true
fi

# Ensure cgroup v2 nesting is enabled
if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
    # cgroup v2
    for i in $(seq 1 5); do
        if sudo sh -c 'echo +cpu +memory +io +pids >> /sys/fs/cgroup/cgroup.subtree_control' 2>/dev/null; then
            break
        fi
        sleep 1
    done
fi

# Start Docker daemon in background (silenced)
echo -n "Starting Docker daemon... "
sudo dockerd >/dev/null 2>&1 &

# Wait for Docker to be ready
for i in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
        echo "ready"
        exit 0
    fi
    sleep 1
done

echo "failed (may not be fully ready)" >&2
