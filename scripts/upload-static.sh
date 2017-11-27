#!/bin/sh

# Upload the static files to a regular webserver (instead od building
# a unikernel)

rsync -avrz --delete htdocs/ dave.recoil.org:/data/www/dave.recoil.org/

