# Live Server Update Recipe



# Production Server Recipe

### Vultr (~ 2 mins)

* New Ubuntu 16.04 Server
* Get IP & root password from server details

### ServerPilot (~ 5 mins)

* Connect New Server
* Set standard password for SP user
* ..Connect

### SSH (~ 5 mins)

* Login to new server IP as user `serverpilot`
* `SU` to root and change password to standard
* Add `serverpilot    ALL=(ALL:ALL) ALL` beneath the equivalent line for root in `/etc/sudoers`
* `dpkg-reconfigure locales`, use en_AU.UTF8
* `dpkg-reconfigure tzdata` Australia\Melbourne
* `apt-get install python`
* 
* `exit` from root!

* Set up ssh keys (copy `authorized_keys` to `~/.ssh/authorized_keys`)
* `chmod 700` ~/ssh
* `chmod 600` ~/ssh/authorized_keys
* Test log in by key instead of password

### DNS Cloudflare

* A record to point to the new IP if required

### ServerPilot (~ 2 mins)

* Create App `imagescience`
* Add domains if needed, e.g. `production.imagescience.com.au`
* Create database using appropriate details from `config/db.php`

### Ansible (~ 5 mins)

* Add/change server IP in ansible `hosts` file
* `cdd`
* `./host.sh play/setup-server.yaml`
* You'll get a message telling you to run sple.sh at this point, see next step

### SSH - Let's Encrypt

* `/usr/local/bin.sple.sh`
* App: `imagescience`
* Domains e.g.: `imagescience.com.au | etc.imagescience.com.au`
* *** IF THIS FAILS SEE BELOW
* Add the entry it recommends to crontab

### Ansible (~ 10 mins)

* On server, remove existing app folder: `rm -rf ~/apps/imagescience/public`
* `./whatever.sh run/deploy-dev-code.yaml`
* `./whatever.sh run/deploy-dev-db.yaml`


### Reboot!

* Should come up as a shiny new server now!
* Run a cache warmer to trigger local creation of all the transforms etc


# Deployment Issues / Manual Interventions

This document should contain any step we haven't been able to satisfactorily automate via ansible.


## Let's Encrypt

Let's encrypt script is fiddly and has to be manually run once.  It should then renew automatically forever more though.

To run, you need to:

 * If present, delete `/etc/nginx-sp/vhosts.d/imagescience.ssl.conf`
 * If present, modify `/etc/apache-sp/vhosts.d/imagescience.d/z_imagescience-production.conf`  to remove the SSL & canoncial re-directs. 

 (Note the z_ on this file is intentional so it's loaded as the last .conf) 

(To modify that file, copy it to local via sftp, edit, copy back - editing via Opus by double click does not copy it back).

Then, run (as root):

```
service apache-sp restart
service nginx-sp restart
```

Check that the http, not https, version loads at:

http://whatever.imagescience.com.au

Run as root

`/usr/local/bin/sple.sh`

..check that succeeds and 

`cat /etc/letsencrypt/live/whatever.imagescience.com.au/fullchain.pem`

...shows a cert.

Re-modify `z_imagescience-production.conf` to add back the SSL stuff etc, can copy back in place.

Restart service again.

Reload at 

https://production.imagescience.com.au

