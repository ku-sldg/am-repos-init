#!/bin/bash
set -eu

if [ -z ${AM_REPOS_ROOT+x} ]; then
  echo "Variable 'AM_REPOS_ROOT' is not set" 
  echo "Run: 'export AM_REPOS_ROOT=<path-to-am_repos_root>'"
  usage
  exit 1
fi

AM_CAKEML_REPO_URL=https://github.com/ku-sldg/am-cakeml.git
AM_CAKEML_BRANCH=copland-lib-pub-adts
AM_CAKEML_LOCAL_DIR=$AM_REPOS_ROOT/am-cakeml

ASP_LIBS_REPO_URL=https://github.com/ku-sldg/asp-libs.git
ASP_LIBS_BRANCH=copland-lib-pub-adts
ASP_LIBS_LOCAL_DIR=$AM_REPOS_ROOT/asp-libs

AM_CLIENTS_REPO_URL=https://github.com/ku-sldg/rust-am-clients.git
AM_CLIENTS_BRANCH=asp_args
AM_CLIENTS_LOCAL_DIR=$AM_REPOS_ROOT/rust-am-clients

# clone am-cakeml
./scripts/clone_branch.sh $AM_CAKEML_REPO_URL $AM_CAKEML_BRANCH "$AM_CAKEML_LOCAL_DIR"

# clone asp-libs
./scripts/clone_branch.sh $ASP_LIBS_REPO_URL $ASP_LIBS_BRANCH "$ASP_LIBS_LOCAL_DIR"

# clone rust-am-clients
./scripts/clone_branch.sh $AM_CLIENTS_REPO_URL $AM_CLIENTS_BRANCH "$AM_CLIENTS_LOCAL_DIR"

echo "Trying to build(make) asp-libs repo"
cd $ASP_LIBS_LOCAL_DIR && make

echo "Trying to build(make) rust-am-clients repo"
cd $AM_CLIENTS_LOCAL_DIR && make

echo ""
echo ""
echo "NEXT STEP:  Proceed to $AM_CAKEML_LOCAL_DIR and follow build instructions in README.md"
echo ""