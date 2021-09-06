#!/bin/bash

# ---------------------------------
# system: centos 7+
# usage： chmod u+x
# author: @raindrop_crz
# version： v1.02  2021.09.06
# warning: remove it after use!
# download url: https://raw.githubusercontent.com/cdd233/Script/master/CentOS_7.sh
# ----------------------------------


echo -e "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
echo -e "| ip addr:\t\t`hostname -I`"
echo -e "| running time:\t\t`date '+%Y-%m-%d %H:%M:%S'`"
echo -e "| linux version:\t`cat /etc/redhat-release`"
echo -e "| current directory:\t`pwd`"
echo -e "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
echo -e "\n\n"



echo -e "[ls /var/log/audit/]"
ls /var/log/audit/
echo -e "\n"
audit_min_dir=`ls /var/log/audit/ | head -1`
echo -e "audit_min_dir ===>> $audit_min_dir"

audit_max_dir=`ls /var/log/audit/ | tail -1`
echo -e "audit_max_dir ===>> $audit_max_dir"
echo -e "\n\n"
echo -e "\n\n"



echo "=========身份鉴别========="
echo -e "\n"

echo "[最后登录时间:]"
lastlog | grep -v Never
echo -e "\n\n"


echo "[/etc/passwd]"
cat /etc/passwd | awk -F ':' '{OFS="\t\t"}{print $1,$4,$7}'
echo -e "\n\n"

echo "[/etc/shadow]"
cat /etc/shadow | awk -F ':' '{OFS="\t\t"}{print $1,$2,$4,$5}'
echo -e "\n\n"

echo "[/etc/sudoers]"
cat /etc/sudoers | grep -v ^"Defaults" | grep -v ^# | grep -v ^$
echo -e "\n\n"

echo "[/etc/group]"
cat /etc/group | grep -E ":0:|:10:"
echo -e "\n\n"


echo "[口令最长有效周期 + MAYBE口令长度:]"
cat /etc/login.defs | grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN" | grep -v ^#
echo -e "\n\n"


# CentOS 7+: pam_pwquality.so
# CentOS 7-: pam_cracklib.so
echo "[口令复杂度:]"
cat /etc/pam.d/system-auth | grep pam_pwquality.so | grep -v ^#
cat /etc/pam.d/system-auth | grep pam_cracklib.so | grep -v ^#
echo -e "\n\n"


# CentOS 8+: pam_faillock.so
# CentOS 8-: pam_tally2.so
echo "[登录失败处理:]"
cat /etc/pam.d/system-auth | grep pam_faillock.so | grep -v ^#
cat /etc/pam.d/system-auth | grep pam_tally2.so | grep -v ^#
echo -e "\n\n"


echo "[SSH远程管理登录失败处理:]"
cat /etc/pam.d/sshd | grep "pam_tally2.so" | grep -v ^#
echo -e "\n\n"



echo "[空闲等待时间:]"
cat /etc/profile | grep TMOUT | grep -v ^#
echo -e "\n\n"



echo "[SSH远程管理服务状态:]"
systemctl list-unit-files --type=service | grep sshd
echo -e "\n"
service sshd status | grep -B5 Active
echo -e "\n\n\n\n\n\n"







echo "=========访问控制========="
echo -e "\n"

echo "[查看文件权限:]"
ls -l /etc/shadow
ls -l /etc/passwd
ls -l /etc/group
ls -l /etc/sudoers
ls -l /etc/pam.d/system-auth
echo -e "\n\n"


echo "[是否允许root远程 + 免密登录 + IP限制: sshd_config]"
cat /etc/ssh/sshd_config | grep -E "PermitRootLogin|PermitEmptyPasswords|AllowUsers" | grep -v ^#
echo -e "\n\n"



echo "[安全标记功能:]"
cat /etc/selinux/config | grep SELINUX= | grep -v ^#
echo -e "\n\n\n\n\n\n"







echo "=========安全审计========="
echo -e "\n"

echo "[审计相关服务1: rsyslog + auditd]"
systemctl list-unit-files --type=service | grep -E "rsyslog|auditd"
echo -e "\n"

service rsyslog status | grep -B5 Active
echo -e "\n"
service auditd status | grep -B5 Active
echo -e "\n\n"


echo "[日志审计规则:]"
auditctl -l
echo -e "\n\n"


echo "[最新10条审计记录: $audit_min_dir]"
tail -10 "/var/log/audit/$audit_min_dir"
echo -e "\n"

echo "[最旧10条审计记录: $audit_max_dir]"
head -10 "/var/log/audit/$audit_max_dir"
echo -e "\n"

echo "[audit日志审计时间:]"
timestamp_start=`head -1 /var/log/audit/$audit_max_dir | awk -F ':' '{print $1}' | awk -F '(' '{print $2}'`
echo -e "Start Time:\t`date -d@$timestamp_start "+%Y-%m-%d %H:%M:%S"`"
timestamp_end=`tail -1 /var/log/audit/$audit_min_dir | awk -F ':' '{print $1}' | awk -F '(' '{print $2}'`
echo -e "End Time:\t`date -d@$timestamp_end "+%Y-%m-%d %H:%M:%S"`"
echo -e "\n\n"


echo "[最新5条审计记录: messages]"
tail -5 "/var/log/messages"
echo -e "\n"

echo "[最旧5条审计记录: messages]"
head -5 "/var/log/messages"
echo -e "\n\n"


echo "[rsyslog转发至日志服务器:]"
cat /etc/rsyslog.conf | grep "\*\.\*" | grep -v ^#
echo -e "\n\n"

echo "[日志保存策略:]"
cat /etc/logrotate.conf | grep -v ^# | grep -v ^$
echo -e "\n\n"


echo "[定时计划任务:]"
crontab -l
echo -e "\n\n"


echo "[审计文件访问权限:]"
ls -l /var/log/messages
ls -l /var/log/secure
ls -l /var/log/audit/audit.log
echo -e "\n\n\n\n\n\n"







echo "=========入侵防范========="
echo -e "\n"

echo "[telnet和ftp服务开启状态:]"
netstat -lnp | grep -E "telnet|ftp"
echo -e "\n\n"


echo "[/etc/hosts.allow]"
cat /etc/hosts.allow | grep -v ^#
echo "[/etc/hosts.deny]"
cat /etc/hosts.deny | grep -v ^#
echo -e "\n\n"

echo "[防火墙服务: ]"
systemctl list-unit-files --type=service | grep firewalld
echo -e "\n"
service firewalld status | grep -B5 Active
echo -e "\n\n"


echo "[系统补丁包:]"
rpm -qa --last | grep patch
echo -e "\n\n\n\n\n\n"









echo "=========系统信息========="
echo -e "\n"

echo "[磁盘使用情况:]"
df -h
echo -e "\n\n"

echo "[内存使用情况:]"
free -m
echo -e "\n\n\n\n\n\n"







echo "[已启用的服务:]"
systemctl list-unit-files | grep enable
echo -e "\n\n"



echo "[已安装的程序:]"
yum list installed
echo -e "\n"



echo "script version ===>> v1.02  2021.09.06"
echo -e "\n"

echo "警告：使用完毕请务必删除！"