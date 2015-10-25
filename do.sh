#!/bin/bash

# Passes any extra args through tp ansible
# call like ./do.sh deploy-git-staging.yaml  (deploys git HEAD to staging)
# ./do.sh deploy-git-staging.yaml --extra-vars "git_version=v0.0.4" (deploys release tagged 'v0.0.4' to staging)

# This turns off cowsays for the humourless amongst us
export ANSIBLE_NOCOWS=1

# setup is special, does various installing things, has to become root

if [[ $1 == "setup-staging.yaml" ]]; then
    ansible-playbook -i hosts --ask-become-pass "$@" 
else
    ansible-playbook -i hosts "$@"
fi


