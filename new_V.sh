#!/bin/bash
#for i in {50..54}
#do
#ssh 192.168.4.$i<<I
#nmcli connection modify eth0 ipv4.method manual ipv4.addresses 192.168.4.$i/24 connection.autoconnect yes
#nmcli connection up eth0
#sed -i '3s/2/4/1' /etc/yum.repos.d/local.repo
#hostnamectl set-hostname "host$i"
#I
img_dir=/var/lib/libvirt/images
xml_dir=/etc/libvirt/qemu
read -p "输入你要创建的虚拟机名字"  vmname
if [ -e $img_dir/$vmname.img ];then
        read -p "此虚拟机已存在,换一个吧:" vmname
fi

read -p "你想要多大内存?[单位KiB,默认1.5G]"  memsize
read -p "你想要多大的磁盘容量[单位:G]?"  dksize
read -p "输入你想要配置的IP地址[192.168.1.?]"  vmip
read -p "输入你要配置的主机名:" hname
#read -p "请选择你要使用的网卡(输入序号)
#        1.private1 (192.168.4.254)
#        2.private2 (192.168.2.254)
#        3.public1  (201.1.1.254)
#        4.public2  (201.1.2.254)
#        5.rhce     (172.25.254.250)
#        6.vbr      (192.168.1.254)" ifs

qemu-img create -b $img_dir/.node_base.qcow2 -f qcow2 $img_dir/$vmname.img $dksize\G
sed  "s/node_base/$vmname/" $img_dir/.node_base.xml > $xml_dir/$vmname.xml
if [ -n "$memsize" ];then
sed -i "s/1524000/$memsize/g"  $xml_dir/$vmname.xml
fi
#case $ifs in

virsh define $xml_dir/$vmname.xml
virsh start $vmname
echo "请等待大约30秒..."
sleep 30
expect<<EOF
spawn virsh console $vmname
expect "换码符为 ^]" {send "\r"}
expect "localhost login:" {send "root\r"}
expect "Password:" {send "a\r"}
expect "#" {send "hostnamectl set-hostname $hname\r"}
expect "#" {send "eip $vmip\r"}
expect "#" {send "systemctl restart network\r"}
expect "#" {send "exit\r"}
expect eof
EOF

#expect<<EOF
#spawn virsh console $vmname
#expect "换码符为 ^]" {send "\r"}
#expect "localhost login:" {send "root\r"}
#expect "Password:" {send "a\r"}
#expect "#" {send "eip 1\r"}
#expect "#" {send "sed -i -e "s/192.168.1.10/$vmip/" -e "s/192.168.1.254/"}
#expect "#" {send "hostnamectl set-hostname $hname\r"}
#expect "#" {send "sed -i '3s/2/4/2' /etc/yum.repos.d/local.repo\r"}
#expect "#" {send "exit\r"}
#expect eof
#EOF

#read -p "需要继续创建虚拟机吗?[y/n]" wtc
#if [ $wtc == y ] &> /dev/null ;then
#	continue
#else
#	exit
#fi
