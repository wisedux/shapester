#!/bin/bash --debugger

################
##
##	SHAPESTER
##		v0.4	20060413
##
##	USAGE
##	shapester
##
##	James B
##	for ____ network babysitting
##
##
##	This program is free software; you can redistribute it and/or
##	modify it under the terms of the GNU General Public License
##	as published by the Free Software Foundation; either version
##	2 of the License, or (at your option) any later version.
##
##	http://www.gnu.org/licenses/gpl.txt
##
################
#
#	Considertions:
#	ICMP type 8 (inbound ping) limits
#	Assuming eth0 and eth1 are bridge, eth2 is for SSH into box
#


## Let's define some variables, no?

iptables=$( which iptables )
tc=$( which tc )

# The interface on the Internet side
outdev=eth0
# The ____ side
indev=eth1
# The remote management interface
mngdev=eth2

# Limit to this transmission rate (kbits/sec)
#rateup=1200
#ratedn=16000


# - - - - - - - -
  scrub () {
# - - - - - - - -

	#### Let's start with some iptables cleaning! ####

	echo "Initializing iptables cleaning."

	# Flush all rules
	$iptables -F

	# Set chain policies
	$iptables -P INPUT DROP
	$iptables -P OUTPUT ACCEPT
	$iptables -P FORWARD ACCEPT
	

	# Allow loopback connections, both ways
	$iptables -A INPUT -i lo -j ACCEPT
	$iptables -A OUTPUT -o lo -j ACCEPT

	# Drop INVALID connections
	$iptables -A INPUT -m state --state INVALID -j DROP
	$iptables -A OUTPUT -m state --state INVALID -j DROP
	$iptables -A FORWARD -m state --state INVALID -j DROP
	
	# Allow all established and related
	$iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	$iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
	
	
	# Allow all useful ICMP types
	
	# Allow ICMP to FORWARD
	# Redundant
	# 	0:  Echo Reply
	$iptables -A FORWARD -p icmp --icmp-type 0 -j ACCEPT
	#	8:  Echo Request
	$iptables -A FORWARD -p icmp --icmp-type 8 -m limit --limit 20/sec -j ACCEPT
	#	11: Time Exceeded
	$iptables -A FORWARD -p icmp --icmp-type 11 -j ACCEPT
	#	12: Parameter Problem
	$iptables -A FORWARD -p icmp --icmp-type 12 -j ACCEPT
	#	13: Timestamp
	$iptables -A FORWARD -p icmp --icmp-type 13 -j ACCEPT
	#	14: Timestamp Reply
	$iptables -A FORWARD -p icmp --icmp-type 14 -j ACCEPT
	#	15: Information Request
	$iptables -A FORWARD -p icmp --icmp-type 15 -j ACCEPT
	#	16: Information Reply
	$iptables -A FORWARD -p icmp --icmp-type 16 -j ACCEPT
	#	30: Traceroute
	$iptables -A FORWARD -p icmp --icmp-type 30 -j ACCEPT
	
	# Allow ICMP to INPUT
	$iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT
	$iptables -A INPUT -p icmp --icmp-type 8 -m limit --limit 10/sec -j ACCEPT
	$iptables -A INPUT -p icmp --icmp-type 11 -j ACCEPT
	$iptables -A INPUT -p icmp --icmp-type 12 -j ACCEPT
	$iptables -A INPUT -p icmp --icmp-type 13 -j ACCEPT
	$iptables -A INPUT -p icmp --icmp-type 14 -j ACCEPT
	$iptables -A INPUT -p icmp --icmp-type 15 -j ACCEPT
	$iptables -A INPUT -p icmp --icmp-type 16 -j ACCEPT
	$iptables -A INPUT -p icmp --icmp-type 30 -j ACCEPT
	 
	# Allow ICMP to OUTPUT
	# Redundant
	$iptables -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
	$iptables -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT
	$iptables -A OUTPUT -p icmp --icmp-type 11 -j ACCEPT
	$iptables -A OUTPUT -p icmp --icmp-type 13 -j ACCEPT
	$iptables -A OUTPUT -p icmp --icmp-type 14 -j ACCEPT
	$iptables -A OUTPUT -p icmp --icmp-type 15 -j ACCEPT
	$iptables -A OUTPUT -p icmp --icmp-type 16 -j ACCEPT
	$iptables -A OUTPUT -p icmp --icmp-type 30 -j ACCEPT
	
	# Log all inbound traffic on $mngdev
	$iptables -A INPUT -i $mngdev -j LOG
	
	# Allow inbound, outbound SSH, port 22
	$iptables -A INPUT -i $mngdev -p tcp -m tcp --dport 22 -j ACCEPT
	$iptables -A OUTPUT -o $mngdev -p tcp -m tcp --dport 22 -j ACCEPT
	
	# Ignore broadcast pings
	echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
	
	# Enable source address spoofing protection
	echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
	
	# Log bogus source addresses
	echo 1 > /proc/sys/net/ipv4/conf/all/log_martians

	# Set outbound MTU
	ip link set dev $outdev mtu 1500

  }


# - - - - - - - -
  get_new_ips () {
# - - - - - - - -

# Adds active local IP addresses to the array


########<to be done later>########

	# Test for /var/shapester.  If not there, make it!
#	if [ ! -x /var/shapester ]; then
#		mkdir /var/shapester
#	fi

#	# Repeat for the file
#	if [ ! -x /var/shapester/active_hosts ]; then
#		touch /var/shapester/active_hosts
#	fi

	# Grab and extract active IPs
#	ngrep -d br0 -e -S 0 'net 192.168.0.0/16' | \
#	sed '192\.168\.[0-9]{1,3}.[0-9]{1,3}/&'

#	 /var/shapester/active_hosts

########</to be done later>########

#	make array of 192.168.10.[2-254] (governable hosts)
#	this is the half-assed way of doing it - to be changed

	prefix="192.168.10."

	declare -a active_hosts_ips=( $( seq 2 254 ) )
#	active_hosts_ips[] is now 2 ... 254

	echo "These hosts are to be limited:"

	for index in $( seq 0 252 )
	do
		active_hosts_ips[ $index ]=$prefix${active_hosts_ips[ $index ]}
		echo ${active_hosts_ips[ $index ]}
	done
#	active_hosts_ips is now 192.168.10.[2 ... 254]
}




# - - - - - - - -
  exists_qdisc () {
# - - - - - - - -

# exists_qdisc device [ingress]
# Return 1 if ingress or root qdisc exists

#	local d=$1
#	local qtype=$2
#	if test "$qtype" = "ingress" ; then

	echo "exists_qdisc does nothing but display this message right now."

}


# - - - - - - - -
  get_status () {
# - - - - - - - -

#	if [ "$1" ]; then local devs=$*; fi
#	for local d in $devs; do
#		exists_qdisc $d
#		if test "$?" -gt "0" ; then

        echo "[qdisc]"
        tc -s qdisc show dev $outdev
        echo "[class]"
        tc -s class show dev $outdev
        echo "[filter]"
        tc -s filter show dev $outdev
	echo "[iptables]"
        iptables -t mangle -L POSTROUTING -v -x 2> /dev/null

  }


# - - - - - - - -
  clean_qdisc () {
# - - - - - - - -

	$tc qdisc del dev $outdev

	#echo "clean_qdisc does nothing but display this message right now."

  }

# - - - - - - - -
  start_qdisc () {
# - - - - - - - -

	# create root handle
	$tc qdisc add dev $outdev root handle 1: htb default ffff

	# give root handle a child class - we need a leaf for each host (!)
	for class_id in $( seq 2 254 )
	do
		$tc class add dev $outdev parent 1: \
		classid 1:$class_id \
		htb rate 36kbit ceil 150kbit
	done
  }

# - - - - - - - -
  start_shaping () {
# - - - - - - - -

	# Filter for all hosts in active_hosts_ips[]
	# dump them in their own queue
## Yes, iptables rocks my socks, but the CLASSIFY target is
## a PITA for newer kernels.
#	for index in $( seq 0 252 )
#	do
#		class_id=$( expr 2 + $index)
#		$iptables -t mangle -A POSTROUTING -o $outdev \
#		-s ${active_hosts_ips[ $index ]} \
#		-j CLASSIFY --set-class 1:$class_id
#	done

## Yes, I know tc u32 flow classification was not made for human eyes...
	for index in $( seq 0 252 )
	do
		class_id=$( expr 2 + $index)
		$tc filter add dev $outdev parent 1: protocol ip u32 \
		match ip src ${active_hosts_ips[ $index ]}/32 \
		flowid 1:$class_id
	done
}

# - - - - - - - -
  end_script () {
# - - - - - - - -

	# this should handle errors, but whatever
	exit 0
  }


#scrub

get_new_ips

clean_qdisc

#get_status

start_qdisc

start_shaping

end_script
