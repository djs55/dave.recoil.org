#!/usr/bin/env bash
ppa=avsm/ocaml41+opam11
echo "yes" | sudo add-apt-repository ppa:$ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam

export OPAMYES=1
opam init
opam install mirage
eval `opam config env`

mirage configure --$MIRAGE_BACKEND
mirage build
# Only deploy if the following conditions are met.
if [ "$MIRAGE_BACKEND" = "xen" \
            -a "$DEPLOY" = "1" \
            -a "$TRAVIS_PULL_REQUEST" = "false" ]; then

    # The Travis worker will already have access to the chunks
    # passed in via the yaml file. Now we need to reconstruct 
    # the GitHub SSH key from those and set up the config file.
    opam install travis-senv
    mkdir -p ~/.ssh
    travis-senv decrypt > ~/.ssh/id_dsa # This doesn't expose it
    chmod 600 ~/.ssh/id_dsa             # Owner can read and write
    echo "Host some_user github.com"   >> ~/.ssh/config
    echo "  Hostname github.com"          >> ~/.ssh/config
    echo "  StrictHostKeyChecking no"     >> ~/.ssh/config
    echo "  CheckHostIP no"               >> ~/.ssh/config
    echo "  UserKnownHostsFile=/dev/null" >> ~/.ssh/config

    # Configure the worker's git details
    # otherwise git actions will fail.
    git config --global user.email "dave@recoil.org"
    git config --global user.name "Travis Build Bot"

    # Do the actual work for deployment.
    # Clone the deployment repo. Notice the user,
    # which is the same as in the ~/.ssh/config file.
    git clone git@some_user:amirmc/www-test-deploy
    cd www-test-deploy

    # Make a folder named for the commit. 
    # If we're rebuiling a VM from a previous
    # commit, then we need to clear the old one.
    # Then copy in both the config file and VM.
    rm -rf $TRAVIS_COMMIT
    mkdir -p $TRAVIS_COMMIT
    cp ../mir-www.xen ../config.ml $TRAVIS_COMMIT

    # Compress the VM and add a text file to note
    # the commit of the most recently built VM.
    bzip2 -9 $TRAVIS_COMMIT/mir-www.xen
    git pull --rebase
    echo $TRAVIS_COMMIT > latest    # update ref to most recent

    # Add, commit and push the changes!
    git add $TRAVIS_COMMIT latest
    git commit -m "adding $TRAVIS_COMMIT built for $MIRAGE_BACKEND"
    git push origin master
    # Go out and enjoy the Sun!
fi
