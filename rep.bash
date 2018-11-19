#!/bin/bash
#
# ------------------------------------------------------------------
# Syntax:
#   $0 <hostname> <file system> <os>
# ------------------------------------------------------------------
# Purpose: This shell script initiates an rsync copy of a Linux OS, Solaris 
#          Solaris, ZFS OS snapshot, or a file system from a customer
#          production VM to a file system, mounted on this server.
#
#          When a Linux OS is replicated, this script updates the 
#          following files with the hostname, IP and MAC addresses, 
#          and OS disk configuration to be used at the secodary site.  
#
#          /boot/grub/grub.conf
#          /etc/fstab
#          /etc/sysconfig/network
#          /etc/sysconfig/network-scripts/ifcfg-eth#
#
#          At the secondary site a single file system is used to house 
#          the /, and /boot file systems.  
# 
# ------------------------------------------------------------------
# Title:          rep.bash
# Author:         Phil Schlegel
# Date:           20141028
# Version:        0.4    
# Notes:          
#
# Rev 0.2 - Tim Bazzie 10/28/2014
#           File Metadata Set:
#           -rwxr-xr--. 1 root scheduler 5.3K Oct 28 14:39 rep.bash
#
# Rev 0.3 - Tim Bazzie 11/05/2014
#           Commented out the 'clear' commands as these garble the log output 
#           to the scheduler.
#
# Rev 0.4 - Phil Schlegel 11/12/2014
#           Added Solaris OS replication and usage to check for correct OS 
#           parameter
#
# Rev 1.0 - Phil Schlegel 3/24/2017
#           - Added os to the syntax explanation at the top of the script. Field
#           os was already in use within the script but was not included in the
#           syntax explanation. 
#           - A check is now performed before each rsync is executed for an 
#           identical job running.  If any identical job is running, the rsync
#           is not executed.  This is done by employing a lock file specific to
#           each job that is deleted after job completion.
#
# -----------------------------------------------------------------------------

# Define functions

grub ()
{

echo -e "Updating grub.conf...\c"

if ! cp /${HOST}/boot/grub/grub.conf{,.prod}
then echo "FAILURE: cp operation of function \"grub ()\""
     exit 4
fi

if ! sed -e 's/\/grub/\/boot\/grub/' -e  's/hd0,0/hd0/' -e 's/vmlinuz/boot\/vmlinuz/' -e 's/initra/boot\/initra/' -e 's/root=LABEL=\//root=\/dev\/xvda1/' /${HOST}/boot/grub/grub.conf > /${HOST}/boot/grub/grub.conf.tmp
then echo "FAILURE: sed operation of function \"grub ()\""
     exit 4
fi

if ! mv /${HOST}/boot/grub/grub.conf.tmp /${HOST}/boot/grub/grub.conf
then echo "FAILURE: mv operation of function \"grub ()\""
     exit 4
fi

echo "done."

}

fstab ()
{

echo -e "Updating file system settings...\c"

if ! cp /${HOST}/etc/fstab{,.prod}
then echo "FAILURE: cp operation of function \"fstab ()\""
     exit 5
fi

if ! sed -e '/LABEL=\/boot/d' -e 's/LABEL=\//\/dev\/xvda1/' -e 's/LABEL=SWAP-VM/\/dev\/xvda3/' /${HOST}/etc/fstab > /${HOST}/etc/fstab.tmp
then echo "FAILURE: sed operation of function \"fstab ()\""
     exit 5
fi

if ! mv /${HOST}/etc/fstab.tmp /${HOST}/etc/fstab
then echo "FAILURE: mv operation of function \"fstab ()\""
     exit 5
fi

echo "done."

}

network ()
{

echo -e "Updating network settings...\c"
#
# Pull VM network data from flat file vm.lst
#
LIST=/usr/local/replication/vm.lst
mgmtMAC=`grep $HOST $LIST | awk '{ print $2 }' `
bkupMAC=`grep $HOST $LIST | awk '{ print $3 }' `
prodMAC=`grep $HOST $LIST | awk '{ print $4 }' `
mgmtIP=`grep $HOST $LIST | awk '{ print $5 }' `
bkupIP=`grep $HOST $LIST | awk '{ print $6 }' `
prodIP=`grep $HOST $LIST | awk '{ print $7 }' `
mgmtGW=`grep $HOST $LIST | awk '{ print $8 }' `
#
# Update management network configuration
#
if ! cp /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth0{,.prod}
then echo "FAILURE: cp operation for mgt network of function \"network ()\""
     exit 6
fi

if ! sed -e "s/.*HWADDR.*/HWADDR=$mgmtMAC/" -e "s/.*IPADDR.*/IPADDR=$mgmtIP/" /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth0 > /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth0.tmp
then echo "FAILURE: sed operation for mgt network of function \"network ()\""
     exit 6
fi

if ! mv /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth0.tmp /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth0
then echo "FAILURE: mv operation for mgt network of function \"network ()\""
     exit 6
fi
#
# Update backup network configuration
#
if ! cp /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth1{,.prod}
then echo "FAILURE: cp operation for bkup network of function \"network ()\""
     exit 6
fi

if ! sed -e "s/.*HWADDR.*/HWADDR=$bkupMAC/" -e "s/.*IPADDR.*/IPADDR=$bkupIP/" /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth1 > /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth1.tmp
then echo "FAILURE: sed operation for bkup network of function \"network ()\""
     exit 6
fi

if ! mv /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth1.tmp /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth1
then echo "FAILURE: mv operation for bkup network of function \"network ()\""
     exit 6
fi
#
# Update production network configuration
#
if ! cp /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth2{,.prod}
then echo "FAILURE: cp operation for prod network of function \"network ()\""
     exit 6
fi

if ! sed -e "s/.*HWADDR.*/HWADDR=$prodMAC/" -e "s/.*IPADDR.*/IPADDR=$prodIP/" /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth2 > /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth2.tmp
then echo "FAILURE: sed operation for prod network of function \"network ()\""
     exit 6
fi

if ! mv /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth2.tmp /${HOST}/etc/sysconfig/network-scripts/ifcfg-eth2
then echo "FAILURE: mv operation for prod network of function \"network ()\""
     exit 6
fi
# 
# Update management gw in routing configuration file
#
if ! cp /${HOST}/etc/sysconfig/network-scripts/route-eth0{,.prod}
then echo "FAILURE: cp operation for gateway of function \"network ()\""
     exit 6
fi

if ! sed -e "s/10.132.185.2/$mgmtGW/" /${HOST}/etc/sysconfig/network-scripts/route-eth0 > /${HOST}/etc/sysconfig/network-scripts/route-eth0.tmp
then echo "FAILURE: sed operation for gateway of function \"network ()\""
     exit 6
fi

if ! mv /${HOST}/etc/sysconfig/network-scripts/route-eth0.tmp /${HOST}/etc/sysconfig/network-scripts/route-eth0
then echo "FAILURE: mv operation for gateway of function \"network ()\""
     exit 6
fi

echo "done."

}

host ()
{

echo -e "Updating host settings...\c"

#
# Update /etc/hosts
#
if ! cp /${HOST}/etc/hosts{,.prod}
then echo "FAILURE: cp operation of function \"host ()\""
     exit 7
fi

if ! sed -e "s/.*$HOST.*/$mgmtIP        $HOST/" /${HOST}/etc/hosts > /${HOST}/etc/hosts.tmp
then echo "FAILURE: sed operation of function \"host ()\""
     exit 7
fi

if ! mv /${HOST}/etc/hosts.tmp /${HOST}/etc/hosts
then echo "FAILURE: mv operation of function \"host ()\""
     exit 7
fi

echo -e "done.\n"

}

usage ()
{

echo "usage: `basename $0` <hostname> [ "os" | <file system> ] [ lin | sol ]" 

}

#

if [ "$#" -ne 3 ]; then
   usage
   exit 2
fi

# Set variables HOST and FS from execution parameters.
# HOST  = hostname of the VM being replicated
# FS    = the file system or OS on the VM to be replicated
# dstamp = the date and time stamp used on the rsync log file

HOST=$1
FS=$2
OS=$3
LOG=/var/log/rsync/${HOST}.$(date +"%Y.%m.%d-%T").log

# clear

# Determine if an identical existing rsync job is running/still running and if so, 
# abort execution of this job.

JOBLOCK=${HOST}.${FS}.${OS}.rsyncjob.lock

if [ -e /tmp/$JOBLOCK ]
then
  echo "Rsync job already running...exiting."
  exit
fi

# Identical job is not running, create lock file.

touch /tmp/${JOBLOCK}

# Delete lock file after completion.

trap 'rm /tmp/${JOBLOCK}' EXIT

# Determine whether the replication is type is OS or specific file system and 
# execute the appropriate rsync command.

if [ $FS = "os" ]; then

   case $OS in 

       'lin')

           if rsync -av --delete --stats --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} root@${HOST}:/* /${HOST} 
           then echo "SUCCESS: rsync of ${HOST} \"os\""
           else echo "FAILURE: rsync of ${HOST} \"os\""
           exit 3
           fi

           # update $HOST/boot/grub/grub.conf
           grub

           # update $HOST/etc/fstab
           fstab

           # update $HOST/etc/sysconfig/network and $HOST/etc/sysconfig/network-scripts/ifcfg-eth#
           network

           # update $HOST/etc/sysconfig/network and $HOST/etc/hosts
           host
           ;;

       'sol')

           if ssh scsadmin@$HOST -c snp.sh
           then echo "SUCCESS: rsync of ${HOST} \"os\""
           else echo "FAILURE: rsync of ${HOST} \"os\""
              exit 3
           fi
           ;;

           *)
           usage
           exit 2
           ;;

   esac

else

   if rsync -av --delete --stats root@${HOST}:${FS}/* /${HOST}/$FS 
   then echo "SUCCESS: rsync of ${HOST}:${FS}"
   else echo "FAILURE: rsync of ${HOST}:${FS}"
      exit 3
   fi
 
fi 

echo -e "Replication Completed Successfully.\n"
exit 0


