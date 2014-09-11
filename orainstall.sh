#!/bin/sh
export PATH=$PATH:/bin:/sbin:/usr/sbin
result=0
echo "**********************************************************************"
echo "*            For Red Hat Enterprise Linux 5.2 x86_64&32              *"
echo "*                                                   ----Add by richy *"
echo "* this script is used to do the prepare work for oracle installation *"
echo "**********************************************************************"

addbaseinfo()
{
 grep -qi oracle /etc/shadow
 result=$?
 if [ 0 -eq $result ]
 then
  echo "The oracle user has exists."
  return -1
 else
  groupadd dba
  groupadd oinstall
  useradd -g oinstall -G dba oracle && echo oracle | passwd --stdin oracle
  mkdir -p /u01/app/oracle/
  mkdir -p /u01/app/oradata
  chown -R oracle. /u01/app/oradata
  chown -R oracle. /u01/app/oracle
  chmod -R 775 /u01/app/oracle /u01/app/oradata
  result=$?
 fi
 if [ 0 -eq $result ]
 then
  echo "Add baseinfo Successfully."
 else 
  echo "Fail to add baseinfo."
  result=-1
 fi;
}

modifysysctl()
{
grep -qi hasbeenadd /etc/sysctl.conf
result=$?
if [ 0 -eq $result ]
then 
 echo "The sysctl.conf had been modified"
 return -1
else
 cat >> /etc/sysctl.conf <<EOF
 #hasbeenadd
 kernel.shmmax=2147483648
 kernel.shmall=2097152
 kernel.shmmni=4096
 kernel.sem=250 32000 100 128
 fs.file-max=65536
 net.ipv4.ip_local_port_range=1024 65000
 net.core.rmem_default=262144
 net.core.wmem_default=262144
 net.core.rmem_max=262144
 net.core.wmem_max=262144
EOF
 result=$?
fi
if [ 0 -eq $result ]
then
 echo "Modify sysctl.conf Successfully."
else
 echo "Fail to modify sysctl.conf."
 result=-1
fi
}


modifylimits()
{
grep -qi oracle /etc/security/limits.conf
result=$?
if [ 0 -eq $result ]
then
 echo "The limits.conf had been modified"
 return -1
else
 cat >> /etc/security/limits.conf <<EOF
 #add by richy for oracle
 oracle    hard    nofile  65536
 oracle    soft    nofile  65536
 oracle    hard    nproc   16384
 oracle    soft    nproc   16384
EOF
result=$?
fi
if [ 0 -eq $result ]
then
 echo "Modify limits.conf successfully"
else
 echo "Fail to modify sysctl.conf"
 result=-1
fi
}

modifylogin()
{
grep -qi pam_limits.so /etc/pam.d/login
result=$?
if [ 0 -eq $result ]
then
 echo "The login had been modified"
 return -1
else
 cat >> /etc/pam.d/login <<EOF
 session required /lib/security/pam_limits.so
EOF
 result=$?
fi
if [ 0 -eq $result ]
then
 echo "Modify login successfully"
else
 echo "Fail to modify login"
 result=-1
fi
}

modifyprofile()
{
oraclepwd=`cat /etc/passwd |awk -F":" '/oracle/{print$6}'`
grep -qi oracle_base ${oraclepwd}/.bash_profile
result=$?
if [ 0 -eq $result ]
then
 echo "The profile had been modified"
 return -1
else
 cat >> ${oraclepwd}/.bash_profile <<EOF
 export ORACLE_BASE=/u01/app/oracle
 export ORACLE_HOME=\${ORACLE_BASE}/product/10.2.0/db_1
 export PATH=\$ORACLE_HOME/bin:\$PATH:\$HOME/bin
 export ORACLE_SID=test
 export ORACLE_OWNER=oracle
 export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$LD_LIBRARY_PATH:/lib:/usr/lib
EOF
 result=$?
 fi
if [ 0 -eq $result ]
then
 echo "profile has been modified"
 chown oracle:oinstall ${oraclepwd}/.bash_profile
else
 result=-1
 echo "Fail to modify the profile for oracle"
fi
}

modifyrelease()
{
grep -qi 5.4 /etc/redhat-release
result=$?
if [ 0 -eq $result ]
then 
 echo "the redhat-release had been modified"
 return -1
else
 sed -ni 's/5\.2/5\.4/' /etc/redhat-release
 result=$?
fi
if [ 0 -eq $result ]
then
 echo "Modified the redhat-release Successfully"
else
 echo "Fail to modify the redhat-release"
 result=-1
fi
}

echo "This script is used to do the prepare work for oracle installion"
addbaseinfo
#result=$?
#if [ 0 -eq $result ];then echo "addbase info successful";fi;
modifysysctl
#result=$?
#if [ 0 -eq $result ];then echo "modify sysctl.conf successfully";fi;
modifylimits
#result=$?
#if [ 0 -eq $result ];then echo "modify limits.conf successfully";fi;
modifylogin
#result=$?
#if [ 0 -eq $result ];then echo "modify login successfully";fi;
modifyprofile
#result=$?
#if [ 0 -eq $result ];then echo "modify .bash_profile successfully";fi;
modifyrelease
#result=$?
#if [ 0 -eq $result ];then echo "modify redhat-release successfully";fi;
sysctl -p
#the glibc-devel 32-bit package is necessary£¬when the installation doing in a 64-bit redhat linux.
yum -y install binutils gcc gcc-c++ glibc glibc-devel* libXp libstdc++ linstdc++-devel make openmotif setarch compat-db control-center
result=$?
if [ 0 -eq $result ]
then
 echo "Package that the oracle depend on are prepared successful." 
else
 echo "Fail to prepare the package oracle depend on"
 result=-1
fi
