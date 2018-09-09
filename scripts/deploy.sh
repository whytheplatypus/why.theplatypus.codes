#!/bin/bash

set -e

git add .
git commit -m "Deploy to GitHub pages"
git push origin master
