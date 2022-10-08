# eniworks

Flatcar is used to host docker containers in an ESXI hypervisor.

The flatcar OVA can be downloaded here

<https://www.flatcar.org/docs/latest/installing/cloud/vmware/>

<https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_vmware_ova.ova>


## generate-flatcar-manifests.sh

This script is used to generate the base64 encoding of the flatcar configuration.

This can be passed into esxi when creating a new VM.

```
./generate-flatcar-manifests.sh workerXX WORKER_IP
```

## flatcar-config.sh

This script handles the installation of kubernetes on the flat car node. 

It's intended to be copied on the flatcar node and ran using sudo.

```
scp flatcar-config.sh core@WORKER_IP:~/
ssh core@WORKER_IP

sudo ./flatcar-config.sh master

# Alternatively, for the worker nodes.
sudo ./flatcar-config.sh worker
```

## toolbox-jail.sh

This script is the bootstrap for my toolbox jail.

Toolbox is a multi-purpose node that handles ldap, mail, and my database.

I've decided to run it as a jail inside truenas as my NAS is my most stable machine and running it locally makes it easy to back up.