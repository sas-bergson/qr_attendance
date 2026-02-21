#!/bin/bash
# Flask runner script using venv

WORKSPACE_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PATH="${WORKSPACE_FOLDER}/backend/venv/bin/python"
export FLASK_APP="backend/app.py"
export FLASK_ENV="development"

cd "${WORKSPACE_FOLDER}/backend"&&"$VENV_PATH" -m flask run --host=0.0.0.0 --port=5000 "$@"
