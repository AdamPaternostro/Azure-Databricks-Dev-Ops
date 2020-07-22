#!/bin/bash

token=$1
path=$2
workspaceUrl=$3
notebookPath=$4

token=""
path=""
workspaceUrl="adb-5980398570403553.13.azuredatabricks.net"
notebookPath="/MyProjects-MyNotebooks"

for f in $path
do

curl -n \
  -F path=$notebookPath \
  -F content=@$f \
  https://$workspace/api/2.0/workspace/import

done