#===============================================================================
#
#          FILE: backup.sh
# 
#         USAGE: ./backup.sh 
# 
#   DESCRIPTION: backup oracle database and copy the newest backup file to the 
#                backup server
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Yangwei(ywei@bjrun.com)
#  ORGANIZATION: 
#       CREATED: 2014-07-17 13:54
#      REVISION: v1.0
#===============================================================================
#!/bin/bash  
#User specific envionment and startup programs
set -o nounset                              # Treat unset variables as an error
if [ -f ~/.bash_profile ];
then
  . ~/.bash_profile
fi
BACIP='192.168.1.1'
IP=`ifconfig|grep "inet addr"|grep -v 127.0.0.1|awk '{print $2}'|cut -d':' -f2|head -1`
BACKUP_PATH="/opt/oracle/oradata/rundata/backup/rman";
BACKUP_LOG="/opt/oracle/oradata/rundata/backup/log";
RMAN_SID="orcl";
RMAN_BIN="/u01/app/oracle/product/10.2.0/db_1/bin/rman";
TIMESTAMP=`date +%Y%m%d%H%M`;
DATE=`date +%Y%m%d`;
DATE_W=`date +%w`;
DATE_D=`date +%d`;

#通过当前日期，确定备份级别
if [ $DATE_W -eq 0 ]; #判断当前时间是否为周日
then
  if [ $DATE_D -le 7 ]; #当前日期小于7，则说明被周日为当前月份的第一个周日，执行0级全库备份。
  then
    INCR_LVL="incremental level 0"
    BACKUP_TYPE=lv0f  #0级全量备份
  else   #其他的周日执行1级累积增量备份
    INCR_LVL="incremental level 1 cumulative"
    BACKUP_TYPE=lv1c  #1级累积增量备份
  fi
else  #非周日的时间，都执行1级差异增量备份
  INCR_LVL="incremental level 2"
  BACKUP_TYPE=lv2d  #1级差异增量备份
fi
#备份集和ssh操作日志名称
RMAN_FILE=${BACKUP_PATH}/${RMAN_SID}_${BACKUP_TYPE}_${TIMESTAMP};
SSH_LOG=${BACKUP_LOG}/${RMAN_SID}_${RMAN_TYPE}_${TIMESTAMP}.log;
RMAN_LOG=${BACKUP_LOG}/${RMAN_SID}_${RMAN_TYPE}_${TIMESTAMP}.log;
#设置最大备份片为8G
MAXPIECESIZE=8G;
#检查RMAN备份的目录有效性
if ! test -d ${RMAN_PATH}
then
  mkdir -p ${RMAN_PATH}
fi
#检查LOG目录有效性
if ! test -d ${RMAN_LOG}
then
  mkdir -p ${RMAN_LOG}
fi
#开始记录ssh操作日志
echo "Rman begin to backup database ............" >>${SSH_LOG}
echo "-------------------------------------------------" >>${SSH_log}
echo "   " >>${SSH_LOG}
echo "Begin time at:" `date` --`date +%Y%m%d%H%M` >>${SSH_LOG}
#备份操作开始    
${RMAN_BIN} log=${RMAN_LOG} <<EOF
connect target /
run {
allocate channel d1 device type disk maxpiecesize=${MAXPIECESIZE};
allocate channel d2 device type disk maxpiecesize=${MAXPIECESIZE};
allocate channel d3 device type disk maxpiecesize=${MAXPIECESIZE};
allocate channel d4 device type disk maxpiecesize=${MAXPIECESIZE};
crosscheck archivelog all;
delete noprompt expired archivelog all;
backup as compressed backupset ${INCR_LVL} database format '${RMAN_FILE}_%U' tag '${RMAN_SID}_${BACKUP_TYPE}_${TIMESTAMP}';
sql 'alter system archive log current';
backup archivelog all format '${RMAN_FILE}_arc_%U' tag '${RMAN_SID}_arc_${TIMESTAMP}' delete all input;
delete noprompt obsolete;
release channel d1;
release channel d2;
release channel d3;
release channel d4;
}
exit;
EOF
RC=$?
#合并RMAN日志到SSH日志中
cat ${RMAN_LOG} >> ${SSH_LOG}
echo "Rman complete backup database at:" `date` --`date +%Y%m%d%H%M` >>${SSH_LOG}
echo >>${SSH_LOG}
echo "-------------------------------" >>${SSH_LOG}

#将最新备份的文件传输到备份服务器的对应IP地址的目下
echo "------Copy the newest backup file to backup server-----" >>${SSH_LOG}
echo "------Begin time at:"`date`  --`date +%Y%m%d%H%M` >>${SSH_LOG}
echo "   " >>${SSH_LOG}
rsync -av --progress --portial --delete -e "ssh -c arcfour" ${BACKUP_PATH} ${IP}:/backup/${IP}
echo "   " >>${SSH_LOG}
echo "------Finsh the copy operation--------" >>${SSH_LOG}
echo "------End time at:"`date`  --`date +%Y%m%d%H%M` >>${SSH_LOG}
