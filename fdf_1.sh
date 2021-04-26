#!/bin/bash

# Timeout set in the second sleep statement
level=2
while [ 1 ]
do
	wlp=$(find /sys/class/net -name "w*" | cut -d '/' -f5)
	rm testfile > /dev/null 2>&1
	status=$(wpa_cli -i $wlp status | grep wpa_state | cut -d '=' -f 2)
	if [ "$status" == "DISCONNECTED" ] || [ "$status" == "INACTIVE" ] || [ "$status" == "INTERFACE_DISABLED" ] || [ "$status" == "SCANNING" ] || [ -z $(hostname -I) ]
	then
		ifdown $wlp > /dev/null 2>&1
		ip link set $wlp up
		wpa_cli -i $wlp scan > /dev/null 2>&1
		sleep 5
		
		wpa_cli -i $wlp scan_results > testfile
		
		n=$(wpa_cli -i $wlp list_networks | awk 'NR==2' | awk '{print $1}')
		
		if [ -z $n ]
		then
			n=$(wpa_cli -i $wlp add_network | awk 'NR==1')
		fi
		
		i=0
		while read line
		do
			array[i]=$line
			((i++))
		done < <(cat testfile | sort -k 3,3 | grep "Schneider Hackware" | awk '{print $1}') 2>/dev/null
		
		array_size=${#array[@]}
	
		for ((i=0;i<$array_size;i++))
		do
			ifdown $wlp > /dev/null 2>&1
			ip link set $wlp up 
		
			wpa_cli -i $wlp disable_network $n > /dev/null 2>&1 
			wpa_cli -i $wlp set_network $n bssid "${array[i]}" > /dev/null 2>&1
			#wpa_cli set_network $n key_mgmt NONE > /dev/null 2>&1
			wpa_cli -i $wlp set_network $n psk '"hackware@forge"' > /dev/null 2>&1
			wpa_cli -i $wlp enable_network $n > /dev/null 2>&1
		
			echo ""
			echo "Current BSSID: ${array[i]}"
			echo ""

			ifup $wlp &
			sleep 15
		
			alive=$(pgrep ifup)
		
			if [ -z $alive ]
			then
				echo ""
				echo "Got lease!"
				echo ""
				rm testfile > /dev/null 2>&1
				break
			else
				echo ""
				echo "TIMEOUT"
				echo ""
				pkill ifup
				pkill dhclient
			fi
		done
		rm testfile > /dev/null 2>&1
	else
		echo ""
		echo "Already connected"
		echo ""
		sleep 3
	fi
done
