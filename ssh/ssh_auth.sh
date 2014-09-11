#===============================================================================
#
#          FILE: ssh_auth.sh
# 
#         USAGE: ./ssh_auth.sh 
# 
#   DESCRIPTION: Bypass password for the connect between linux server using ssh
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Yangwei(ywei@bjrun.com)
#  ORGANIZATION: 
#       CREATED: 2014-07-17 22:17
#      REVISION:  v1.0
#===============================================================================
#!/bin/bash
 
#生成密钥，并将密钥拷贝到本机/tmp/ssh下对应的IP地址目录下
cat ip.list|while read line
do
ip=`echo $line|cut -d' ' -f1`
user=`echo $line|cut -d' ' -f2`
passwd=`echo $line|cut -d' ' -f3`
if [ ! -d /tmp/ssh/$ip ];
then
  mkdir -p /tmp/ssh/$ip
fi

expect <<EOF
spawn ssh $user@$ip ssh-keygen -t rsa
while 1 {
  expect {
    "password:" {send "$passwd\r"}
    "yes/no" {send "yes\r"}
    "Enter file in which to save the key*" {send "\r"}
    "Enter passphrase*" {send "\r"}
    "Enter same passphrase again:" {send "\r"}
    "Overwrite (y/n)" {send "\r"}
    eof {exit}
    }
}
EOF
expect <<EOF
spawn scp $user@$ip:~/.ssh/id_rsa.pub /tmp/ssh/$ip
while 1 {
  expect {
    "yes/no" {send "yes\r"}
    "password:" {send "$passwd\r"}
    eof {exit}
  }
}
EOF
cat /tmp/ssh/$ip/id_rsa.pub >> /tmp/ssh/authorized_keys
done
#将authorized_keys文件scp到各个机器~/.ssh/下
cat ip.list|while read line
do
ip=`echo $line|cut -d' ' -f1`
user=`echo $line|cut -d' ' -f2`
passwd=`echo $line|cut -d' ' -f3`
expect <<EOF
spawn scp /tmp/ssh/authorized_keys $user@$ip:~/.ssh/ 
while 1 {
  expect {
    "yes/no" {send "yes\r"}
    "password:" {send "$passwd\r"}
    eof {exit}
  }
}
EOF
done

#bypass password
cat ip.list|while read line
do
ip=`echo $line|cut -d' ' -f1`
user=`echo $line|cut -d' ' -f2`
passwd=`echo $line|cut -d' ' -f3`
expect <<EOF
spawn ssh $ip date
while 1 {
  expect {
    "yes/no" {send "yes\r"}
    eof {exit}
  }
}
EOF
done
#删除临时目录
rm -fr /tmp/ssh
