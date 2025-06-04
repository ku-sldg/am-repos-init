#!/bin/bash
set -eu

# Function to display usage instructions
usage() {
  echo "Usage: $0 [-b <shared-branch-name>]"
  exit 1
}

if [ -z ${AM_REPOS_ROOT+x} ]; then
  echo "Variable 'AM_REPOS_ROOT' is not set" 
  echo "Run: 'export AM_REPOS_ROOT=<path-to-am_repos_root>'"
  usage
  exit 1
fi

MAESTRO_BRANCH=""

# Parse command-line arguments
while getopts "b:" opt; do
  case ${opt} in
    b )
      MAESTRO_BRANCH=$OPTARG
      ;;
    * )
      usage
      ;;
  esac
done


if [ -z "$MAESTRO_BRANCH" ]; then
  echo "Warning:  No shared branch_name provided, using default branches..."
fi

AM_CAKEML_BRANCH_DEFAULT=master
ASP_LIBS_BRANCH_DEFAULT=main
AM_CLIENTS_BRANCH_DEFAULT=main

AM_CAKEML_REPO_URL=https://github.com/ku-sldg/am-cakeml.git
  if [ -z "$MAESTRO_BRANCH" ]; then
      AM_CAKEML_BRANCH=$AM_CAKEML_BRANCH_DEFAULT
  else AM_CAKEML_BRANCH=$MAESTRO_BRANCH 
  fi
AM_CAKEML_LOCAL_DIR=$AM_REPOS_ROOT/am-cakeml

ASP_LIBS_REPO_URL=https://github.com/ku-sldg/asp-libs.git
  if [ -z "$MAESTRO_BRANCH" ]; then 
    ASP_LIBS_BRANCH=$ASP_LIBS_BRANCH_DEFAULT
  else ASP_LIBS_BRANCH=$MAESTRO_BRANCH 
  fi
ASP_LIBS_LOCAL_DIR=$AM_REPOS_ROOT/asp-libs

AM_CLIENTS_REPO_URL=https://github.com/ku-sldg/rust-am-clients.git
  if [ -z "$MAESTRO_BRANCH" ]; then
      AM_CLIENTS_BRANCH=$AM_CLIENTS_BRANCH_DEFAULT
  else AM_CLIENTS_BRANCH=$MAESTRO_BRANCH 
  fi
AM_CLIENTS_LOCAL_DIR=$AM_REPOS_ROOT/rust-am-clients

# Make a variable for the script directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$REPO_DIR/scripts/"

# clone am-cakeml
$SCRIPT_DIR/clone_branch.sh $AM_CAKEML_REPO_URL $AM_CAKEML_BRANCH "$AM_CAKEML_LOCAL_DIR"

# clone asp-libs
$SCRIPT_DIR/clone_branch.sh $ASP_LIBS_REPO_URL $ASP_LIBS_BRANCH "$ASP_LIBS_LOCAL_DIR"

# clone rust-am-clients
$SCRIPT_DIR/clone_branch.sh $AM_CLIENTS_REPO_URL $AM_CLIENTS_BRANCH "$AM_CLIENTS_LOCAL_DIR"

echo "Trying to build(make) asp-libs repo"
cd $ASP_LIBS_LOCAL_DIR && make

echo "Trying to build(make) rust-am-clients repo"
cd $AM_CLIENTS_LOCAL_DIR && make

echo ""
echo ""
echo "NEXT STEP:  Proceed to $AM_CAKEML_LOCAL_DIR and follow the manual build instructions in README.md"
echo ""