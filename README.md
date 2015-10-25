
# Ansible Deploy CraftCMS to Cloud VPS 

This is a quick guide & set of example [Ansible](http://www.ansible.com/) playbooks for automated deployment of a CraftCMS installation to a VPS server such as a [Digital Ocean](https://www.digitalocean.com/) 'droplet' or [Vultr](https://www.vultr.com/) VPS.  

It's not 100% ready to use out of the box and will take some minor tailoring, but should give you 90%+ of what you need to get going with automated deployments.

Ansible is a script based industrial strength deployment system.  Basically,  like shell scripting or git hooks but...better.  Better in the sense that it is **simpler** (Playbooks are written in very human readable YAML) and **idempotent** - playbooks are fully repeatable and made of modular DRY roles. Ansible keeps track of state so you can repeat the playbooks as often as you want/need and it knows what needs to be repeated and what doesn't, basically - which makes ansible **performant** as well.    

You string 'roles' together to make a highly modular system that can take you from a bare 'droplet' type server to a fully deployed live server in minutes.  

There's a nice article on why it's...simple and elegant, I guess - here: http://www.ansible.com/blog/simplicity-the-art-of-automation

All it really needs on the server is ssh ('agentless deployment'), although if you want to e.g. import DBs on the server it does need some python modules installed (the install of which can be part of your server setup playbook of course).

Server Management of the VPS is done by [ServerPilot](https://serverpilot.io/) - they handle the basics of server performance, security, updating and monitoring.

I currently use Vultr as they have servers in Sydney and you just can't beat those pings.  Even on a $5/month VPS, Craft (with PHP 7) absolutely _flies_.

Written largely for my own benefit, this is not a heavily tested or thoroughly documented and properly configurable system (yet?) - but hopefully it's more than enough to help others get started with similar projects.  

The goal is to go from deploying a new VPS instance to a fully runninng Craft system in less than half an hour.

## BASIC STRUCTURE

In the parent folder we have:

    hosts

Which define the hosts which are in our groups...in this case, we just have one host in each group.   We can also have a section to put host specific variables in this file.

Next up is:

    do.sh

Which is a very simple script that calls `ansible-playbook` to run our plays.  It basically just passes arguments through, which most of the time we won't be doing, but here's some examples anyway:

    ./do.sh setup-staging.yaml
    ./do.sh setup-staging.yaml --start-at-task="setup-server-general|Create script directory"

We then have our master playbooks.  

Each of these defines a particular thing we want to do, and calls the corresponding roles which make those results happen.  Should be pretty much self explanatory, but here are some examples:

    ./do.sh deploy-git-staging.yaml  # deploy git HEAD to staging
    ./do.sh deploy-git-staging.yaml --git_version="v0.0.4" # deploy specific tag to staging

### How to understand what's going to happen in a particular play

Read the master playbook.  It defines the various **roles** - each of which I treat as a modular DRY tasks - that are strung together to achieve goals.

Each role has it's own folder.  Under there, you will find in each a `tasks` folder with a file called main.yaml - these are pretty much human readable task lists.  Just read through each one in order to see what will happen.

There may also be a `files` folder that contains e.g. configuration or credential files that are copied across as part of that role.

Obviously, missing from this repository are _actual_ credential files.  You'll need to add your own.  Don't worry, when you're trying this out ansible will give you excellent error messages so you can just add these as you go.

## VPS SERVER SETUP

OK - Let's Get Started!

There's about 5 minutes of initial GUI based server creation & setup stuff, then the rest is all done via the command line and the excellent deployment system that is ansible.  

Of course, ansible is easily powerful enough that you could add the deployment stuff to your systems as well (using e.g. vagrant/docker etc), so you could go from nothing to fully deployed server with one simple command.

But for now let's just use the popular Serverpilot +  VPS approach.

### Create VPS Server

On Digital Ocean or Vultr etc, create your new VPS:

For Serverpilot to manage it, the base system **must** be:

    Ubuntu 14.04 x64

Wait until the server is deployed and you get an IP address assigned.  This usually takes about a minute. 

### DNS

Optionally, point your DNS to this IP if you want to be ale to access by name rather than IP address.

I use [Cloudflare](https://www.cloudflare.com/) to handle DNS as they have a nice simple interface (and they can do a whole lot of other good stuff for your site if you want).

E.g. in Cloudflare make a new A record

    staging -> Your Server IP

### Connect Server at Server Pilot

Point it at the new server IP and hit connect.  With any luck it finds it and does some initial setup stuff for you:

* Installs: LAMP Stack - actually, a LEMP stack technically - Linux, ngninx proxy for performance, and under that a standard apache, mysql, php setup.  
* Makes a 'serverpilot' user
* Server updates/patching/firewall

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

Basically, though, just add your ssh keys in `.ssh/authorized_keys`

    touch ~/.ssh/authorized_keys
    cat >> ~/.ssh/authorized_keys

...and paste in your ssh keys (for your deployment machine and any other machine you want to easily log in from).

(You can also then disable ssh access by password if you like).

### Optional: Set up sudo for your Serverpilot user

`su` so you're temporarily root, and add serverpilot to /etc/sudoers like this:

    root    ALL=(ALL) ALL  # Under this line add:
    serverpilot     ALL=(ALL) ALL

(Some might (would) argue against doing that but it's very handy). 

### Create an SSH key for the VPS, user serverpilot

To deploy from your hosted git repo, you will need to add a public key for the serverpilot user to e.g. your [bitbucket](https://bitbucket.org/) private repository deployment keys.  

To generate your public and private key, run:

    ssh-keygen

You public key will then be found in `~/.ssh` as `ida_rsa.pub`


### Set up SSL - Self Signed or Otherwise

Of course you're only going to run this site over https, right?  I use the very simple [Patrol plugin](https://github.com/selvinortiz/craft.patrol) to re-direct _all_ access to SSL.

But to do this, you're going to need to install an SLL certificate for your app.

#### Create CSR & Key

In Serverpilot, Create your [CSR and Key](https://serverpilot.io/community/articles/generate-an-ssl-key-and-csr.html).

Now, go get your SSL certificate signed by your paid provider, or, if it's jsut a development/staging server, you can...

#### Optional: Self Sign Your Key

[Serverpilot guide to self signing keys](https://serverpilot.io/community/articles/how-to-create-a-self-signed-ssl-certificate.html) is available, but it's really just running this is `~/.ssh`:

    openssl x509 -req -days 365 -in ssl.csr -signkey ssl.key -out ssl.crt

#### Either way, Copy Certificate Back to Serverpilot

...and then hit 'update'.

Now, you can visit your site at https://ip-address or https://site-name.com or whatever.  You'll get those scary warnings in your browser if you self signed of course.  

If everything was done properly, you should see the default Serverpilot App page.

### Optional: Setup htaccess to prevent undesired premature Google indexing etc

Again, there is a good [Serverpilot guide](https://serverpilot.io/community/articles/how-to-password-protect-a-directory.html) available.

We will deploy the `.htaccess` and `.htpasswd` as part of deployment to our staging server, so we actually save these files under the 'release' role - see `/release/files/` for examples.


### Optional: General Server Configuration (hostname, timezone etc)

Some extra handy server setup stuff is to set up your hostname and configure where you are so your times etc. are right:

    sudo hostname staging.projectname.com.au  #Needed with Vultr only
    sudo dpkg-reconfigure locales
    sudo dpkg-reconfigure tzdata


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

`do.sh` is how you actually run the master playbooks and get stuff to happen.

### Roles

Each role has its own folder and in that is another folder `tasks` with a playbook of actions in it, e.g.

    setup-server-general/tasks/main.yml

The `setup` roles are generally just run once and set up some basic stuff on the server to prepare for the later deployments - such as setting installing required packages via `apt`, and setting up hourly database backups to Amazon S3 etc.

(If you were going for full automatic server deployment, you could e.g. have it create the database and user here as well - basically all your one off server and app setup jobs).


### Master Playbooks - Config and List of Roles

We have a master playbook for each of the major things we want to achieve, which call on our smaller defined modular, DRY rolls.

We also define configuration and control variables here to control behaviour in the roles if needed.

So for example `deploy-dev-staging.yaml` holds the configuration needed for deploying my latest dev code to the staging server, and the roles required to achieve the goal:

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

This sets up some config - we tell it we want to deploy our local DB (ie. run `mysqldump` locally, and push the dumpt to ther server).  And import it at the other end.

To achieve the deployment, we run through 5 roles.

    common          # this sets up common configuration variables
    deploy-dev      # uses rsync to push up my local craft and public_html folders
    push-local-db   # dumps my local db and imports it on the server
    release         # symlinks the server's craft and public folders to these deployed files
    clean-up        # delete older releases etc if needed

Now - you should have a look through all the roles and change them to your needs - ansible has [excellent documentation](http://docs.ansible.com/ansible/intro.html).  

Basically there's a module for anything and each is very simple and pretty much emulates what you'd run on the command line but in a simpler, more human readable form.

## ACTUALLY DEPLOYING

 So, starting from our 5 minute configured new VPS, to go to a full deployment from our current local code & DB, all we run on our local server is this:

    ./do.sh setup-staging.yaml
    ./do.sh deploy-dev-staging.yaml

If we want to deploy a specific git version, we would change that second lime to:

    ./do.sh deploy-git-staging --git_version="V0.0.4"  # Can use any commit SHA-1 or tag here

...if we don't specify git_version it will deploy HEAD of course.

(and you could add this one liner as a git post-commit hook if you want to make this automatic when you commit each change, for example).









