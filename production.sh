#!/bin/bash

# Passes any extra args through to ansible
# ./production.sh play/deploy-git.yaml --extra-vars "git_version=v0.0.4" 
# (deploys release tagged 'v0.0.4' to production)

ansible-playbook -i hosts --ask-become-pass --extra-vars "host=production" "$@" 

