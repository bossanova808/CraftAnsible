
This folder stores playbooks.  Each playbook calls on one or more `roles` in `deployment/roles` to do the actual work.

So, this folder contains all the playbooks we want to be able to run - atomic 'recipes' to achieve particular server tasks.

The formula for running these is, from your deployment folder which is kept in your project root folder

`cd deployment`
`./server.sh play/playbook.yaml`

`server.sh` is usually `staging.sh` or `production.sh`.  There is a one line shell script for each of your servers in `deployment` so just copy and create more of these it need be.

`playbook.yaml` you replace with the name of the actual play you want to runn.

This gives you a very declarative way of running your plays - what server you're running it on followed by what playbook you are running:

`./production.sh play/pull-db.yaml`


