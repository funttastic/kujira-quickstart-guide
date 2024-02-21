#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

source "$SCRIPT_DIR/common.sh"

actions_menu
