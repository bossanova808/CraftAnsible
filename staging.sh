#!/bin/bash

# Passes any extra args through to ansible
# ./staging.sh play/deploy-git.yaml --extra-vars "git_version=v0.0.4" 
# (deploys release tagged 'v0.0.4' to staging)

ansible-playbook -i hosts --ask-become-pass --extra-vars "host=staging" "$@" 

