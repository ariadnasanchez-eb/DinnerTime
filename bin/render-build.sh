#!/usr/bin/env bash
# Build script for Render: install gems, compile assets and run migrations.
set -o errexit

bundle install
bin/rails assets:precompile
bin/rails assets:clean
bin/rails db:prepare
