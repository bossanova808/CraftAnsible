This folder stores roler.  Each 'role' is a specific goasl we want to achieve on a server, and is made up of a series of tasks.

Example:
deploy-dev - deploys your current dev code to a server
deploy-git - deploys git HEAD or a specific git tag to a server
pull-production-db - pulls the production db to your local server

etc.

The idea is to keep the roles small, simple and atomic.  If any files are needed the are taken from the root `deployment/files` folder.

Playbooks will join roles together to achieve higher level tasks, thus we end up with the hierachy

Playbook (e.g setup-server)

....runs roles

e.g setup-server-general

...each of which runs a series of tasks

e.g. apt-update, intall tools like pjepoptim, copy various credentials, etc.