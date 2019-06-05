# Tutorial material for the CernVM Workshop 2019

## Overview

This tutorial covers the deployment of a CernVM-FS publication system based on
the repository gateway and the Conveyor job system.

A set of VMs has been provisioned for use during this tutorial:

* `cvm19-front-$ID.cern.ch` - the frontend machine where the test CernVM-FS
  repository can be mounted and inspected and jobs can submitted
* `cvm19-gw-$ID.cern.ch` - the gateway machine where the CernVM-FS repository is
  created (serves as Stratum-0) and the `cvmfs-gateway`, `conveyor-server` and
  `cvmfs-notify` services are run.
* `cvm19-publisher-1-$ID.cern.ch` and `cvm19-publisher-2-$ID.cern.ch` are
  publisher machines, where the CernVM-FS publisher tools and the Converyor
  worker daemon are run.

To determine the exact name of the VMs you are supposed to use, replace the
`$ID` part of the hostnames with the actual value given to you at the start of
the tutorial.

The VMs have already have some initial configuration applied: installing some
CVMFS and some prerequisites, opening some firewall ports, etc. The Ansible
playbook `setup.yml` can be consulted to review this configuration.

To connect to the VMs, use the SSH key distributed at the start of the tutorial

## CVMFS Repository Gateway

In this part of the tutorial, a new CVMFS repository will be created and
configured for use with the repository gateway. Two distinct machines will also be configured to publish content to the new repository.

First, connect to the gateway machine:
```bash
$ ssh -i ~/.ssh/id_rsa_cvm19 root@cvm19-gw-$ID.cern.ch
```

Enable Apache:
```bash
$ systemctl enable httpd && systemctl start httpd
```

Create the new CernVM-FS repository:
```bash
$ cvmfs_server mkfs -o root cvm19.cern.ch
```

Create the gateway key, for example:
```bash
$ cat <<EOF > /etc/cvmfs/keys/cvm19.cern.ch.gw
plain_text key1 big_secret
EOF
```

Save the public and repository keys for transfer to other VMs:
```bash
$ mkdir ~/keys && cp -v /etc/cvmfs/keys/cvm19.cern.ch.{crt,pub,gw} ~/keys/
```

Add the repository to the gateway configuration file (`/etc/cvmfs/gateway/repo.json`), as follows:
```json
{
    "version": 2,
    "repos" : [
        "cvm19.cern.ch"
    ]
}
```

Enable and start the gateway service:
```bash
$ systemctl enable cvmfs-gateway && systemctl start cvmfs-gateway
```

Connect to the frontend machine to mount the repository for reading:
```bash
$ ssh -i ~/.ssh/id_rsa_cvm19 root@cvm19-front-$ID.cern.ch
```

Copy the public repository keys from the gateway machine to the default location on the frontend machine (`/etc/cvmfs/keys`).

Initialize the CVMFS configuration:
```bash
$ cvmfs_config setup
```

Create a configuration file (`/etc/cvmfs/config.d/cvm19.cern.ch.conf`) for the repository, with the following contents:
```bash
CVMFS_HTTP_PROXY=DIRECT
CVMFS_SERVER_URL=http://cvm19-gw-$ID.cern.ch/cvmfs/cvm19.cern.ch
CVMFS_KEYS_DIR=/etc/cvmfs/keys
```

Start AutoFS:
```bash
$ systemctl enable autofs && systemctl start autofs
```

The repository can now be accessed:
```bash
$ ls /cvmfs/cvm19.cern.ch/
```

Connect to the first publisher machine:
```bash
$ ssh -i ~/.ssh/id_rsa_cvm19 root@cvm19-publisher-1-$ID.cern.ch
```

The public and gateway keys can be retrieved from the gateway machine and stored in (`$HOME/keys`). The repository can be initialized for publishing:
```bash
$ cvmfs_server mkfs -o root -k ~/keys -u gw,/var/spool/cvmfs/cvm19.cern.ch/tmp/,http://cvm19-gw-$ID.cern.ch:4929/api/v1 -w http://cvm19-gw-$ID.cern.ch/cvmfs/cvm19.cern.ch cvm19.cern.ch
```

The same steps can be repeated on the second publisher machine (`cvm19-publisher-2-$ID.cern.ch`). Concurrent transactions can now be started from the two publisher machines, as long as the paths do not conflict. Feel free to experiment before moving on to the next step of the tutorial.

## CVMFS Conveyor

With the repository gateway and the two publishers up and running, this part of the tutorial covers the Conveyor job system. The Conveyor server is started on the gateway machine and the Conveyor worker daemon is started on the two publisher machines. At that point, it will be possible to submit publication jobs to the Conveyor system.

The Conveyor system depends on RabbitMQ and a SQL database as backing services. For convenience, a Docker Compose file is provided on the gateway machine which starts the RabbitMQ and PostgreSQL services in containers. Connect to the gateway machine and run:
```bash
$ cd ~/conveyor-services && docker-compose up -d
```

For convenience, the PostgreSQL credentials are (user: "postgres", pass: "password"), while the RabbitMQ credentialas are (user: "guest", pass: "guest").

After the backing services are up, the database schema used by the Conveyor server should be created
```bash
$ psql -h localhost -p 5432 -U postgres -W -d cvmfs -f initdb/create_conveyor_schema.sql
```

Example Conveyor configuration files are provided in this repo inside `conveyor-config`, for the frontend machine (`config_front.toml`), publisher (`config_publisher.toml`), and gateway (`config_gw.toml`). The host names should be adjusted in each configuration file using your actual `$ID` value. Afterward, place the configuration files on the corresponding machine at `/etc/cvmfs/conveyor/config.toml`).

The Conveyor system can now be started. On the gateway machine, start the Conveyor server:
```bash
$ systemctl start conveyor-server@root
```

On the publishers, start the Conveyor workers:
```bash
$ systemctl start conveyor-worker@root
```

The logs of these services can be inspected as follows:
```bash
$ journalctl -u conveyor-server@root
```

From the frontend, jobs can be submitted with the `conveyor submit` command. Please see the scripts `submit_jobs.sh` and `test_transaction.sh` for examples.

## CVMFS Repository Notification System

The final part of the tutorial covers the notification system. The notification service is started on the gateway machine and can be used to distributed the repository manifest to the subscribers of the notification system.

Copy the file, `config_notify.json` to the gateway machine, at `/etc/cvmfs/notify/config.json`. Start the notification service:
```bash
$ systemctl enable cvmfs-notify && systemctl start cvmfs-notify
```

To test the notifications from the frontend VM, you can use the `cvmfs_swissknife` tool. The following sets up a subscription for messages related to the current repository:
```bash
$ cvmfs_swissknife notify -s -u http://cvm19-gw-$ID.cern.ch:4930/api/v1/subscribe -t cvm19.cern.ch -c
```

The following command, publishes the current manifest of the repository to all subscribers:
```bash
cvmfs_swissknife notify -p -u http://cvm19-gw-$ID.cern.ch:4930/api/v1/publish -r http://cvm19-gw-$ID.cern.ch/cvmfs/cvm19.cern.ch
```

The CVMFS mountpoint can also subscribe to notifications by setting the
following variable:
```bash
CVMFS_NOTIFICATION_SERVER=http://cvm19-gw-$ID.cern.ch:4930/api/v1/subscribe
```
inside `/etc/cvmfs/config.d/cvm19.cern.ch.conf`.

## References

* CernVM-FS [ReadTheDocs](https://cvmfs.readthedocs.io/en/stable/).
