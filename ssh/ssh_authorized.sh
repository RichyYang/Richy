#!/bin/bash
 
#生成密钥文件authorized_keys
cat ip.list|while read line
do
ip=`echo $line|cut -d' ' -f1`
user=`echo $line|cut -d' ' -f2`
passwd=`echo $line|cut -d' ' -f3`
#判断对应IP的目录是否存在，不存在，则自动创建
if [ ! -d /tmp/ssh/$ip ];
then
  mkdir -p /tmp/ssh/$ip
fi
#在对应的IP的服务器本机生成公钥文件id_rsa.pub
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
#将各服务器的id_rsa.pub文件拷贝到本地/tmp/ssh的对应IP地址目下
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
#生成密钥认证文件authorized_keys
cat /tmp/ssh/$ip/id_rsa.pub >> /tmp/ssh/authorized_keys
done

#在讲authorized_keys文件scp到各个机器~/.ssh/下
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
#删除临时目录
rm -fr /tmp/ssh
