#!/bin/bash
#
# Copyright (c) 2009-2014 finfra.com <nowage@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

echo "########################################################################"
echo "########################################################################"
. ~/_setting_h2/doAll.sh


# hadoop version
hadoopVersion=`cat /root/_setting_h2/hadoopVersion`

# Java setting
x=`rpm -qa|grep java-1.7`
if [ ${#x} -eq 0 ];then
    yum -y install  java-1.7
fi

x=`ls -als \`which /usr/bin/java\`|awk '{print $NF}'`
y=`ls -als $x|awk '{print $NF}'`
z=${y/\/bin\/java/}
z1=${z/\/jre/}
echo $z1>/root/_setting_h2/javaHome

export javaHome=`cat /root/_setting_h2/javaHome`
 cd /root/_setting_h2
 #Set Variable
 hostCnt=$(grep -c ".*" ~/_setting_h2/host)

# shutdown firewall.
x=`cat /etc/redhat-release|sed -e 's/CentOS Linux release \([6,7]\)[\(\)\ \.0-9a-zA-Z]*/\1/g' `
if [ $x -eq 7 ];then
    centOsVersion=7
    y=`ps -ef |grep firewalld|grep -v grep`
    if [ ${#y} -ne 0 ];then
        systemctl disable firewalld
        systemctl stop firewalld
    fi
else
    centOsVersion=6
    y=`service iptables status|grep Chain`
    if [ ${#y} -ne 0 ];then
        chkconfig iptables off
        service iptables stop
    fi
fi

# make script access
chmod 755 /root/
chmod 755 /root/_setting_h2
. hSetup1ByRoot.sh namenode

for i in `seq 2 $hostCnt`;do
	# shutdown firewall.
    if [ centOsVersion = 7 ]; then
        sshpass -f ~/.ssh/pass ssh s$i systemctl disable firewalld
    elif [ centOsVersion = 6 ]; then
    	sshpass -f ~/.ssh/pass ssh s$i chkconfig iptables off
    	sshpass -f ~/.ssh/pass ssh s$i service iptables stop
    fi
	# make script access
 	sshpass -f ~/.ssh/pass ssh s$i chmod 755 /root/
    sshpass -f ~/.ssh/pass ssh s$i "if [ ! -d /root/_setting_h2 ];then mkdir /root/_setting_h2; fi"
 	sshpass -f ~/.ssh/pass ssh s$i chmod 755 /root/_setting_h2
 	sshpass -f ~/.ssh/pass ssh s$i ls /root/hadoop-$hadoopVersion.tar.gz
 	x=`sshpass -f ~/.ssh/pass ssh s$i ls /root/|grep hadoop-$hadoopVersion.tar.gz$`
 	if [ ${#x} -eq 0 ];then
 		echo copying hadoop-$hadoopVersion.tar.gz
 		sshpass -f ~/.ssh/pass scp /root/hadoop-$hadoopVersion.tar.gz          s$i:/root
 	fi
 	sshpass -f ~/.ssh/pass scp /root/_setting_h2/*    s$i:/root/_setting_h2/
 	sshpass -f ~/.ssh/pass ssh s$i . ~/_setting_h2/hSetup1ByRoot.sh $i
done




cp -r /root/_setting_h2 /home/hadoop/_setting_h2
chown -R  hadoop /home/hadoop/_setting_h2

cat ~/.ssh/pass > /home/hadoop/.ssh/pass
chown hadoop /home/hadoop/.ssh/pass
sshpass -f ~/.ssh/pass ssh hadoop@s1 . /home/hadoop/_setting_h2/doAll.sh


for i in `seq 2 $hostCnt`;do
	sshpass -f ~/.ssh/pass ssh hadoop@s$i  /root/_setting_h2/hSetup3ByHadoop.sh $i
done
sshpass -f ~/.ssh/pass ssh hadoop@s1  /root/_setting_h2/hSetup3ByHadoop.sh  'namenode'
echo "########################################################################"
echo "########################################################################"
