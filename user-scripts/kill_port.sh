#!/bin/bash

while getopts "p:" opt; do
  case $opt in
  p)
    port=$OPTARG
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    exit 1
    ;;
  esac
done

if [ -z "$port" ]; then
  echo "Error: Port number not specified."
  exit 1
fi

echo "Finding the process running on port $port..."
process_id=$(lsof -t -i:$port)

if [ -z "$process_id" ]; then
  echo "No process found running on port $port"
else
  echo "Killing process $process_id running on port $port..."
  kill $process_id
fi
