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

## CVMFS Repository Gateway

In this part of the tutorial, a new CVMFS repository will be created and
configured for use with the repository gateway. Two distinct machines will also be configured to publish content to the new repository.

## CVMFS Conveyor

With the repository gateway and the two publishers up and running, this part of the tutorial covers the Conveyor job system. The Conveyor server is started on the gateway machine and the Conveyor worker daemon is started on the two publisher machines. At this point, it is possible to submit publication jobs to the Conveyor system.

## CVMFS Repository Notification System

The final part of the tutorial covers the notification system. The notification service is started on the gateway machine and can be used to distributed the repository manifest to the subscribers of the notification system.

## References

* CernVM-FS [ReadTheDocs](https://cvmfs.readthedocs.io/en/stable/).