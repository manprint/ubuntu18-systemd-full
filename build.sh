#!/bin/bash

echo "Script name: build"
echo "******************"

docker build --tag adiprint/ubuntu18-systemd-full:latest .

