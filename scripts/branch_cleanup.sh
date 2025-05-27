#!/bin/bash

if [ -z ${AM_REPOS_ROOT+x} ]; then
  echo "Variable 'AM_REPOS_ROOT' is not set" 
  echo "Run: 'export AM_REPOS_ROOT=<path-to-am_repos>'"
  usage
  exit 1
fi

AM_CAKEML_LOCAL_DIR=$AM_REPOS_ROOT/am-cakeml
ASP_LIBS_LOCAL_DIR=$AM_REPOS_ROOT/asp-libs
AM_CLIENTS_LOCAL_DIR=$AM_REPOS_ROOT/rust-am-clients

rm -rf $AM_CAKEML_LOCAL_DIR
rm -rf $ASP_LIBS_LOCAL_DIR
rm -rf $AM_CLIENTS_LOCAL_DIR