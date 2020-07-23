#!/bin/bash

echo "Init-Script Started"

echo $DB_IS_DRIVER
if [[ $DB_IS_DRIVER = "TRUE" ]]; then
  echo "Executing this code on driver ONLY"
else
  echo "Executing this code on workers ONLY"
fi

echo "Executing this code on drivers and workers"

echo "Init-Script Completed"