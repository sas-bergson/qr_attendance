#!/bin/bash
# pgAdmin4 startup script

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/venv/lib/python3.10/site-packages/pgadmin4"
"$SCRIPT_DIR/venv/bin/python" pgAdmin4.py
