#!/bin/bash

set -e

git config --global user.email "$GH_EMAIL" 
git config --global user.name "$CIRCLE_USERNAME"
git init
git remote add --fetch origin "$PAGES_REMOTE"
git add -A
git commit -m "Deploy to GitHub pages"
git push origin master
