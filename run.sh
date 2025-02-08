#!/bin/bash

while true; do
    screen -dm bash -c "bash dl-1.sh"
    screen -dm bash -c "bash dl-2.sh"
    screen -dm bash -c "bash dl-3.sh"

    wait  # صبر می‌کند تا هر سه اجرا تمام شوند، سپس ادامه می‌دهد
done
