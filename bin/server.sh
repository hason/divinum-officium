#!/bin/sh

set -e

carmel exec plackup -r -R public app.psgi
