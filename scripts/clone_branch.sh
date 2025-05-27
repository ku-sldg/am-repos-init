#!/bin/bash

# Set the repository URL and branch name
repo_url="$1"
branch_name="$2"
local_dir="$3"

# Check if the repository URL and branch name are provided
if [ -z "$repo_url" ] || [ -z "$branch_name" ] || [ -z "$local_dir" ]; then
  echo "Usage: $0 <repository_url> <branch_name> <local_dir>"
  exit 1
fi

# Check if the local directory already exists
if [ -d "$local_dir" ]; then
  echo "Directory '$local_dir' already exists. Skipping clone."

else

  # Clone the specific branch
  git clone -b "$branch_name" --single-branch "$repo_url" "$local_dir"

  # Check if the clone was successful
  if [ $? -eq 0 ]; then
    echo "Successfully cloned branch '$branch_name' from '$repo_url' into '$local_dir'"
  else
    echo "Failed to clone branch '$branch_name' from '$repo_url' into '$local_dir'"
    exit 1
  fi
fi