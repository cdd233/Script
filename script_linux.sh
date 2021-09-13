#!/bin/bash

# ---------------------------------
# system: Part Of The Linux System
# usage： chmod u+x
# author: @raindrop_crz
# version： v1.05  2021.09.13
# warning: remove it after use!
# download url: https://raw.githubusercontent.com/cdd233/Script/master/script_linux.sh
# ----------------------------------


if [ -a /etc/redhat-release ]
then
    linux_release=`grep -i centos /etc/redhat-release`
else
    linux_release=`lsb_release -i | awk -F ':\t' '{print $NF}'`" "`lsb_release -r | awk -F ':\t' '{print $NF}'`
fi


case `echo $linux_release | awk -F ' ' '{print $1}'` in
    CentOS)
        authentication_path="/etc/pam.d/system-auth"
        package_manager_command="rpm -qa --last"
        ;;
    Ubuntu|Debian|Kali)
        authentication_path="/etc/pam.d/common-password"
        package_manager_command="dpkg-query -l"
        ;;
    *)
        echo "Could not found Linux release，exit now!"
        exit 1
esac




echo -e "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
echo -e "| ip addr:\t\t`hostname -I`"
echo -e "| running time:\t\t`date '+%Y-%m-%d %H:%M:%S'`"
echo -e "| linux version:\t`echo $linux_release`"
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
lastlog | grep -v "\*\*"
echo -e "\n\n"


echo "[/etc/passwd]"
echo -e "USER\t\tGID\t\tSHELL"
grep -v "nologin\|false" /etc/passwd | awk -F ':' '{OFS="\t\t"}{print $1,$4,$7}'
echo -e "\n\n"

echo "[/etc/shadow]"
echo -e "USER\t\tMIN_DAYS\t\tMAX_DAYS\t\tLAST_PASSWD\t\tPASSWD"
for i in `grep -v "nologin\|false" /etc/passwd | awk -F ':' '{print $1}'`
do
    for j in `grep $i /etc/shadow | awk -F ':' '{print $3}'`
    do
        next_passwd_time=`date -d "19700101 +$j days" "+%Y.%m.%d"`
        grep $i /etc/shadow | awk -F ':' '{OFS="\t\t"}{print $1,$4,$5,"'$next_passwd_time'",$2}'
    done
done
echo -e "\n\n"

echo "[/etc/sudoers]"
grep -v '^Defaults\|^#\|^$' /etc/sudoers
echo -e "\n\n"

echo "[/etc/group]"
for i in `grep -v "nologin\|false" /etc/passwd | awk -F ':' '{print $1}'`; do grep $i /etc/group; done
echo -e "\n\n"


echo "[口令最长有效周期 + MAYBE口令长度:]"
grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN" /etc/login.defs | grep -v ^#
echo -e "\n\n"


# CentOS 7+: pam_pwquality.so
# CentOS 7-: pam_cracklib.so
echo "[口令复杂度: ]"
grep pam_pwquality.so $authentication_path | grep -v ^#
grep pam_cracklib.so $authentication_path | grep -v ^#
echo -e "\n\n"


# CentOS 8+: pam_faillock.so
# CentOS 8-: pam_tally2.so
echo "[登录失败处理:]"
grep pam_faillock.so $authentication_path | grep -v ^#
grep pam_tally2.so $authentication_path | grep -v ^#
echo -e "\n\n"



echo "[空闲等待时间:]"
grep TMOUT /etc/profile | grep -v ^#
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
ls -l $authentication_path
echo -e "\n\n"


echo "[是否允许root远程 + 免密登录: sshd_config]"
grep -E "PermitRootLogin|PermitEmptyPasswords" /etc/ssh/sshd_config | grep -v ^#
echo -e "\n\n"



echo "[安全标记功能:]"
grep SELINUX= /etc/selinux/config | grep -v ^#
echo -e "\n\n\n\n\n\n"







echo "=========安全审计========="
echo -e "\n"

echo "[审计相关服务: rsyslog + auditd]"
systemctl list-unit-files --type=service | grep -E "rsyslog|auditd"
echo -e "\n"

service rsyslog status | grep -B5 Active
echo -e "\n"
service auditd status | grep -B5 Active
echo -e "\n\n"



echo "[最新5条审计记录: $audit_min_dir]"
tail -5 "/var/log/audit/$audit_min_dir"
echo -e "\n"

echo "[最旧5条审计记录: $audit_max_dir]"
head -5 "/var/log/audit/$audit_max_dir"
echo -e "\n"

echo "[audit日志审计时间:]"
timestamp_start=`head -1 /var/log/audit/$audit_max_dir | awk -F ':' '{print $1}' | awk -F '(' '{print $2}'`
echo -e "Start Time:\t`date -d@$timestamp_start "+%Y-%m-%d %H:%M:%S"`"
timestamp_end=`tail -1 /var/log/audit/$audit_min_dir | awk -F ':' '{print $1}' | awk -F '(' '{print $2}'`
echo -e "End Time:\t`date -d@$timestamp_end "+%Y-%m-%d %H:%M:%S"`"
echo -e "\n\n"


echo "[日志审计规则:]"
auditctl -l
echo -e "\n\n"


echo "[审计配置策略: auditd.conf]"
grep -E "log_file|num_logs|max_log_file|max_log_file_action" /etc/audit/auditd.conf | grep -v '^#\|^$'
echo -e "\n\n"


echo "[转发至日志服务器: rsyslog.conf]"
grep "\*\.\*" /etc/rsyslog.conf | grep -v ^#
echo -e "\n\n"

echo "[日志保存策略: logrotate.conf]"
grep -v '^#\|^$' /etc/logrotate.conf
echo -e "\n\n"


echo "[定时计划任务:]"
crontab -l
echo -e "\n\n"


echo "[审计文件访问权限:]"
ls -l /var/log/messages
ls -l /var/log/secure
ls -ld /var/log/audit
echo -e "\n\n\n\n\n\n"







echo "=========入侵防范========="
echo -e "\n"

echo "[telnet和ftp服务开启状态:]"
netstat -lnp | grep -E "telnet|ftp"
echo -e "\n\n"


echo "[网络地址接入限制: sshd_config]"
grep -E "AllowUsers|DenyUsers" /etc/ssh/sshd_config | grep -v ^#
echo -e "\n\n"

echo "[/etc/hosts.allow]"
grep -v '^#\|^$' /etc/hosts.allow
echo "[/etc/hosts.deny]"
grep -v '^#\|^$' /etc/hosts.deny
echo -e "\n\n"


echo "[系统补丁包:]"
$package_manager_command | grep patch
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
$package_manager_command | sort
echo -e "\n"



echo "script version ===>> v1.05  2021.09.13"
echo -e "\n"

echo "警告：使完毕请务必在主机上删除本文件！"