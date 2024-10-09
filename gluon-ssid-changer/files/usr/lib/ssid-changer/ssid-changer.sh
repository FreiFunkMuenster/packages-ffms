#!/bin/sh

# definitions

ONLINE_SSID=$(uci -q get wireless.client_radio0.ssid)
: ${ONLINE_SSID:=Freifunk}   # if for whatever reason ONLINE_SSID is NULL
OFFLINE_PREFIX='FF_OFFLINE_' # use something short to leave space for the nodename

UPPER_LIMIT='55' # above this limit the online SSID will be used
LOWER_LIMIT='45' # below this limit the offline SSID will be used
# between these two values the SSID will never be changed to prevent it from toggeling every minute

# generate an offline SSID with the first and last part of the nodename to allow owner to recognize which node is down
NODENAME=`uname -n`
if [ ${#NODENAME} -gt $((30 - ${#OFFLINE_PREFIX})) ] ; then # 32 would be possible as well
	HALF=$(( (28 - ${#OFFLINE_PREFIX} ) / 2 )) # calculate the length of the first part of the node identifier in the offline SSID
	SKIP=$(( ${#NODENAME} - $HALF )) # jump to this character for the last part of the name
	OFFLINE_SSID=$OFFLINE_PREFIX${NODENAME:0:$HALF}...${NODENAME:$SKIP:${#NODENAME}} # use the first and last part of the nodename for nodes with long name
else
	OFFLINE_SSID="$OFFLINE_PREFIX$NODENAME" # great, we are able to use the full nodename in the offline ssid
fi

# Is there an active gateway?
GATEWAY_TQ=`batctl gwl | grep -e "^=>" -e "^\*" | awk -F'[()]' '{print $2}'| tr -d " "` # grep the connection quality of the gateway which is currently used

if [ ! $GATEWAY_TQ ]; # no gateway
then
	GATEWAY_TQ=0 # just an easy way to get a valid value if there is no gatway
fi

if [ $GATEWAY_TQ -gt $UPPER_LIMIT ];
then
	echo "Gateway TQ is $GATEWAY_TQ, node is online"
	for HOSTAPD in $(ls /var/run/hostapd-phy*); do # check status for all physical devices
		CURRENT_SSID=`grep "^ssid=$ONLINE_SSID" $HOSTAPD | cut -d"=" -f2`
		if [ $CURRENT_SSID == $ONLINE_SSID ]
		then
			echo "SSID $CURRENT_SSID is correct, nothing to do"
			HUP_NEEDED=0
			break
		fi
		CURRENT_SSID=`grep "^ssid=$OFFLINE_SSID" $HOSTAPD | cut -d"=" -f2`
		if [ $CURRENT_SSID == $OFFLINE_SSID ]
		then
			logger -s -t "gluon-offline-ssid" -p 5 "TQ is $GATEWAY_TQ, SSID is $CURRENT_SSID, change to $ONLINE_SSID" # write info to syslog
			sed -i s/^ssid=$CURRENT_SSID/ssid=$ONLINE_SSID/ $HOSTAPD
			HUP_NEEDED=1 # HUP here would be too early for dualband devices
		else
			echo "Something is wrong, did not find SSID $ONLINE_SSID or $OFFLINE_SSID"
		fi
	done
fi

if [ $GATEWAY_TQ -lt $LOWER_LIMIT ];
then
	echo "Gateway TQ is $GATEWAY_TQ, node is considered offline"
	for HOSTAPD in $(ls /var/run/hostapd-phy*); do # check status for all physical devices
		CURRENT_SSID=`grep "^ssid=$OFFLINE_SSID" $HOSTAPD | cut -d"=" -f2`
		if [ $CURRENT_SSID == $OFFLINE_SSID ]
		then
			echo "SSID $CURRENT_SSID is correct, nothing to do"
			HUP_NEEDED=0
			break
		fi
		CURRENT_SSID=`grep "^ssid=$ONLINE_SSID" $HOSTAPD | cut -d"=" -f2`
		if [ $CURRENT_SSID == $ONLINE_SSID ]
		then
			logger -s -t "gluon-offline-ssid" -p 5 "TQ is $GATEWAY_TQ, SSID is $CURRENT_SSID, change to $OFFLINE_SSID" # write info to syslog
			sed -i s/^ssid=$ONLINE_SSID/ssid=$OFFLINE_SSID/ $HOSTAPD
			HUP_NEEDED=1 # HUP here would be to early for dualband devices
		else
			echo "Something is wrong, did not find SSID $ONLINE_SSID or $OFFLINE_SSID"
		fi
	done
fi

if [ $GATEWAY_TQ -ge $LOWER_LIMIT -a $GATEWAY_TQ -le $UPPER_LIMIT ]; # TQ is between LOWER_LIMIT and UPPER_LIMIT
then
	echo "TQ is $GATEWAY_TQ, do nothing"
	HUP_NEEDED=0
fi

if [ $HUP_NEEDED == 1 ]; then
	killall -HUP hostapd # send HUP to all hostapd to load new SSID
	HUP_NEEDED=0
	echo "HUP!"
fi
