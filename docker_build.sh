#!/usr/bin/env bash

docker build -t  crash-libpython --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .
