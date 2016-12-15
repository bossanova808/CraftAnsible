
# Ansible Deploy CraftCMS to Cloud VPS 

This is a quick guide & set of example [Ansible](http://www.ansible.com/) playbooks for automated deployment of a CraftCMS installation to a VPS server such as a [Digital Ocean](https://www.digitalocean.com/) 'droplet' or [Vultr](https://www.vultr.com/) VPS. 

It handles pretty much all of the initial server setup, and on-going deployments.  It's not generalised or ready to use out-of-the-box.  It requires some tailoring to your needs, but should give you 95%+ of what you need to get going with fully automated server setup and Craft deployments.

Ansible is a script based industrial strength deployment system.  Basically,  like shell scripting or git hooks but...better.  

**Better** in the sense that it is **simpler** (Playbooks are written in very human readable YAML) and that it aims to be **idempotent** - playbooks are fully repeatable and made of modular DRY roles. Ansible keeps track of state so you can repeat the playbooks as often as you want/need and it knows what needs to be repeated and what doesn't, basically - which makes ansible **performant** as well.   

You string 'roles' together to make a highly modular system that can take you from a bare 'droplet' type server to a fully deployed, secure live server in minutes.  

There's a nice article on why it's...simple and elegant, I guess - here: http://www.ansible.com/blog/simplicity-the-art-of-automation

All it really needs on the server is standard ssh (this is called 'agentless deployment' - although if you want to e.g. import DBs on the server it does need some python modules installed (the install of which can be part of your server setup playbook of course!).

Server Management of the VPS is, in this example, done by [ServerPilot](https://serverpilot.io/) - they handle the basics of server performance, security, updating and monitoring.  

For ther servers themselves, you can really use any of the standard providers that can give you a bare, Ubuntu 16.04 VPS, such as Digital Ocean, Vultr, Linode, etc.  I currently use Vultr as they have servers in Sydney and you just can't beat those pings.  Even on a $5/month VPS, Craft (with PHP 7) absolutely _flies_.

I've written this largely for my own benefit, and use it in production myself - even this document is here largely as a self reminder system - but hopefully it's more than enough to help others get started with similar projects.  

The goal is to go from deploying a new VPS instance to a fully runninng Craft system in less than half an hour, and to use ansible for all deployment tasks on an ongoing basis (deploying new code, pushing and pull DBs etc).

Apart from ongoing deployments, this is really my disaster recovery plan - that is, if ever there is a major outage on my current VPS provider, I can simply switch to another and run a few simple commands to redeploy everything & restore my db backups to a new, bare VPS and swithc over IPs - wa la, a new production server in less than an hour.  (Hourly db backups to s3 are set up as part of this system!).

## BASIC STRUCTURE

In the parent folder we have:

    hosts

Which define the hosts which are in our groups...in this case, we just have one host in each group.   We can also have a section to put host specific variables in this file.

Next up is:

    do.sh (generalised one)
    production.sh (Run stuff on production)
    staging.sh (you can guess, right?)

Which are _very_ simple scripts that calls `ansible-playbook` to actually run our play books.  It basically just passes arguments through, which most of the time we won't be doing, but here's some examples anyway:

    ./production.sh play/setup-server.yaml 

...which automatically sets up a bare Ubuntu VPS to host Craft

    ./staging.sh play/deploy-dev-code.yaml 

...which deploys current local develompment code straight from your local dev environment to the staging server.

### Playbooks

We then have our master playbooks in the `play` folder.  This gives a nice  declarative command line syntax as per the above examples.  

Each of the playbooks in `play` define a particular thing we want to do, and calls the corresponding `role` (or roles) which make those results happen.  Should be pretty much self explanatory, but here are some examples:

    ./staging.sh play/deploy-git.yaml  

...deploys git HEAD to staging

    ./production.sh play/deploy-git.yaml --git_version="v0.0.4" 

....deploys a specific git tag to production

### How to understand what's going to happen in a particular play

Read the master playbook.  It defines the various **roles** - each of which I treat as a modular DRY tasks - that are strung together to achieve goals.

Each role has it's own folder under `roles`.  

Under there, you will find in each a `tasks` folder with generally just a file called `main.yaml` - these are pretty much human readable task lists.  Just read through each one in order to see what will happen.

### How to set up for your server

In the `files` folder you will find configuration & credential files that are copied across as part of that role....you need to change the various `whatever` in there to suit your needs/environment.  (Indeed, you should `grep` this whole repo for `whatever` and change any you find to a sensible value!)

(Obviously, missing from this repository are _actual_ credentials.  You'll need to add your own.  Don't worry, when you're trying this out ansible will give you excellent error messages so you can, if you like, just add these as you go).

## VPS SERVER SETUP

OK - Let's Get Started!

There's about 5 minutes of initial GUI based server creation & setup stuff, then the rest is all done via the command line and the excellent deployment system that is ansible.  

Of course, ansible is easily powerful enough that you could add the deployment stuff to your systems as well (using e.g. vagrant/docker etc), so you could go from nothing to fully deployed server with one simple command.

But for now let's just use the popular Serverpilot +  VPS approach.

### Create VPS Server

On Digital Ocean or Vultr etc, create your new VPS:

For Serverpilot to manage it, the base system **must** be:

    Ubuntu 16.04 x64

Wait until your shiny new server is deployed and you get an IP address assigned.  This usually takes about a minute. 

### DNS

Optionally, point your DNS to this IP if you want to be able to access by name rather than IP address.

I use the brilliant free [Cloudflare](https://www.cloudflare.com/) plan to handle DNS as they have a very nice, simple interface (and they can do a whole lot of other good stuff for your site if you want - including static asset caching which massively speeds up your site!).

E.g. in Cloudflare make a new A record

    staging -> Your Server IP

### Connect Server at Server Pilot

Point it at the new server IP and hit connect.  With any luck it finds it and does some initial setup stuff for you, including:

* Installs: LAMP Stack - actually, a LEMP stack technically - Linux, ngninx proxy for performance, and under that a standard apache, mysql, php setup.  
* Makes a `serverpilot` user
* Server updates/patching/firewall setup

This takes a couple of minutes, at the end of it you have a nice, secure, up to date and ready to go VPS with your full LEMP stack, including choice of PHP version.

You deploy apps under serverpilot/apps/ but intially this can all be done by GUI in ServerPilot. Again, we coud do all this with ansible scripts but it's nice to keep ServerPilot aware of the basics of your apps, so we take a couple of minutes and do this in the ServerPilot GUI.

### Create Your App in Serverpilot

Choose PHP7 of course.  It makes Craft really fly.  

Give your app a sensible name, although you can't use non-alphanumeric characters unfortunately, so probably just best to use the project name:

    projectname

### Create Database & Database User

In Serverpilot, limited to 16 characters, so e.g.:

    database: craft_projectname
    user: craft_projectname

### Set up SSH on your VPS

There's a nice [Serverpilot guide to SSH public key authentication](https://serverpilot.io/community/articles/how-to-use-ssh-public-key-authentication.html).

Basically, though, just add your private ssh keys in `.ssh/authorized_keys` like this:

    touch ~/.ssh/authorized_keys
    cat >> ~/.ssh/authorized_keys

...and paste in your ssh keys (obviously you need the key for your deployment machine, plus any other machine you want to easily log in from).

(You can also then disable ssh access by password if you like once you've done this!).

### Set up sudo for your Serverpilot user

`su` so you're temporarily root, and add serverpilot to /etc/sudoers like this:

    root    ALL=(ALL:ALL) ALL  # Under this line add:
    serverpilot     ALL=(ALL:ALL) ALL

This allows ansible to become `root` when it needs to.

### Optional: Create an SSH key for the VPS, user serverpilot

To deploy code from your hosted git repo, you will need to add a public key for the serverpilot user to e.g. your [bitbucket](https://bitbucket.org/) private repository deployment keys so that bitbucket can access the server during deployment. 

To generate your public and private key, run:

    ssh-keygen

You public key will then be found in `~/.ssh` as `ida_rsa.pub`  - copy this to bitbucket deployment keys or the equivalent for your code host.

### Optional: General Server Configuration (hostname, timezone etc)

Some extra handy server setup stuff is to set up your hostname and configure where you are so your times etc. are right:

    sudo hostname staging.projectname.com.au  #Needed with Vultr only
    sudo dpkg-reconfigure locales
    sudo dpkg-reconfigure tzdata

## ANSIBLE SERVER SETUP

Now, you're ready to rock and roll with some ansible automation

    ./staging.sh play/setup-server.yaml

..will kick that off (on your host called staging defined in `hosts` in the root of your deployment folder).

This will set up pretty much everything about your server - including html5 boilerplate, mysql optimisations, auto hourly database backups to S3, imagemagick and node.js installations, etc.  Just read all the playbooks to see the magic & of course modify for your needs!

This usually takes about 10 minutes or so to complete.

### Manually Set Up Free SSL - Let's Encrypt

My ansible server setup script installs a script to make getting free certificates from Let's Encrypt simple.  However you will need to run this manually after the initial server setup as it requires user input.

Essentially, after the server setup, run as root:

`/usr/local/bin/sple.sh`

...and follow the on-screen prompts.


## ANSIBLE DEPLOYMENT

## Ansible Configuration

I store the deployment folder in my apps root folder and have a top level structure that looks like this:

    /deployment/
    /craft/   # craft lives under here
    /public_html/ - basically empty as my node gulp task builds the css/js etc

So, under `deployment`, change the `hosts` file to reflect your servers.  

Note this setup is for a simple scenario of one dev having their own local dev server, with one staging VPS and one production VPS and doesn't deal with more complex things like db sync across multiple devs etc.

### Basic Structure (Again)

In root `deployment` folder:

`hosts` defines your hosts, as one server, each in one of two groups - staging and production

E.g. `production.sh` is how you actually run the master playbooks and get stuff to happen on that server.

### Roles

Each role has its own folder and in that is another folder `tasks` with a playbook of actions in it, e.g.

    setup-server-general/tasks/main.yml

The `setup` roles are generally just run once and set up some basic stuff on the server to prepare for the later deployments - such as setting installing required packages via `apt`, and setting up hourly database backups to Amazon S3 etc.

(If you were going for full automatic server deployment, you could e.g. have it create the database and user here as well - basically all your one off server and app setup jobs).


### Master Playbooks - Config and List of Roles

We have a master playbook for each of the major things we want to achieve, which call on our smaller defined modular, DRY rolls.

We also define configuration and control variables here to control behaviour in the roles if needed.

So for example `deploy-dev-code.yaml` holds the configuration needed for deploying my latest dev code to a server, and the roles required to achieve the goal:

    ---
    - hosts: staging

      vars:
        deploy_local_db: "true"
        import_db: "true"

      roles:
        - common
        - deploy-dev
        - push-local-db
        - release
        - clean-up

This sets up some config - we tell it we want to deploy our local DB (ie. run `mysqldump` locally, and push the dump to the server).  And import it at the other end.

To achieve the deployment, we might e.g. run through 5 roles.

    common          # this sets up common configuration variables
    deploy-dev      # uses rsync to push up my local craft and public_html folders
    push-local-db   # dumps my local db and imports it on the server
    release         # symlinks the server's craft and public folders to these deployed files
    clean-up        # delete older releases etc if needed

Now - you should have a look through all the roles and change them to your needs - ansible has [excellent documentation](http://docs.ansible.com/ansible/intro.html).  

Basically there's a module for anything and each is very simple and pretty much emulates what you'd run on the command line but in a simpler, more human readable form.

## Practical Exmaples 

### ACTUALLY DEPLOYING TO A NEW BARE SERVER - Current Dev Code

 So, starting from our bare new VPS, to go to a full deployment from our current local code & DB, all we run on our local server is this:

    ./staging.sh play/setup-server.yaml
    ./staging.sh play/deploy-dev-db.yaml
    ./staging.sh play/deploy-dev-code.yaml

If we want to instead deploy a specific git version, we would change that second line to:

    ./staging.sh deploy-git --extra-vars "git_version=V0.0.4"  # Can use any commit SHA-1 or tag here

(...if we don't specify git_version it will deploy HEAD of course.)

(and you could add this one liner as a git post-commit hook if you want to make this automatic when you commit each change, for example).

### Pushing dev code/db to staging for testing

    ./staging.sh play/deploy-dev-code.yaml
    ./staging.sh play/deploy-dev-db.yaml
   
### Doing a hotfix with live production data

For example, with an ecommerce site, for a quick fix it's usually better to just have a little downtime but be completely sure about state of data, so we take it offline, do a quick fix, and then push the fix and any db changes back up to the production server before making it accesible again:

In full this:

* Triggers maintenance mode 
  (n.b. this requires a console command plugin I wrote to do this)
* Pulls the latest production DB to your local dev
* (You then make changes and test, before tagging and committing)
* (Optional) -> Push the potentially updated DB back to production
* Deploy the updated code from git
* Disables maintenance mode on the live server

And here's the actual process:

    git checkout -b hotfix-whatever
    ./production.sh play/pull-db.yaml
    ./production.sh play/maintenance-enable.yaml

... Work locally & **Test!**

Them, git merge in your fix & tag a release, something like:

    git commit -m "Fixed bug whatever"
    git checkout master
    git merge hotfix master
    git push origin master
    git tag -a v1.4.1 -m "Merged hotfix for..."
    git push origin --tags
    git branch -d hotfix-whatever

Push the tagged git version to production:

    ./production.sh play/deploy-git --extra-vars "git_version=V1.4.1"

Push the dev db which is now the production db plus the local changes

    ./production.sh play/deploy-dev-db

(...this will aslo take your site out of maintenance mode since you pulled the DB just before enabling maintenance mode)





   






