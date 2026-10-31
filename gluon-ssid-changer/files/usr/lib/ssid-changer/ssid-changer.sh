#!/bin/sh

# definitions

ONLINE_SSID=$(uci -q get wireless.client_radio0.ssid)
: ${ONLINE_SSID:=Freifunk}   # if for whatever reason ONLINE_SSID is NULL
OFFLINE_PREFIX='FF_OFFLINE_' # use something short to leave space for the nodename

UPPER_LIMIT='55' # above this limit the online SSID will be used
LOWER_LIMIT='45' # below this limit the offline SSID will be used
# between these two values the SSID will never be changed to prevent it from toggeling every minute

# generate an offline SSID with the first and last part of the nodename to allow owner to recognize which node is down
NODENAME=$(uname -n)
if [ ${#NODENAME} -gt $((30 - ${#OFFLINE_PREFIX})) ] ; then # 32 would be possible as well
	HALF=$(( (28 - ${#OFFLINE_PREFIX} ) / 2 )) # calculate the length of the first part of the node identifier in the offline SSID
	SKIP=$(( ${#NODENAME} - $HALF )) # jump to this character for the last part of the name
	OFFLINE_SSID=$OFFLINE_PREFIX${NODENAME:0:$HALF}...${NODENAME:$SKIP:${#NODENAME}} # use the first and last part of the nodename for nodes with long name
else
	OFFLINE_SSID="$OFFLINE_PREFIX$NODENAME" # great, we are able to use the full nodename in the offline ssid
fi

# escape a string for use as basic regular expression in sed
sed_regex() {
	printf '%s' "$1" | sed -e 's/[]\/$*.^[]/\\&/g'
}

# escape a string for use as replacement in sed
sed_replacement() {
	printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

# Is there an active gateway?
GATEWAY_TQ=$(batctl gwl | grep -e "^=>" -e "^\*" | awk -F'[()]' '{print $2}' | tr -d " ") # grep the connection quality of the gateway which is currently used

case "$GATEWAY_TQ" in
	''|*[!0-9]*) GATEWAY_TQ=0 ;; # no gateway or unparseable output
esac

if [ "$GATEWAY_TQ" -gt "$UPPER_LIMIT" ]; then
	echo "Gateway TQ is $GATEWAY_TQ, node is online"
	CURRENT_SSID=$OFFLINE_SSID
	TARGET_SSID=$ONLINE_SSID
elif [ "$GATEWAY_TQ" -lt "$LOWER_LIMIT" ]; then
	echo "Gateway TQ is $GATEWAY_TQ, node is considered offline"
	CURRENT_SSID=$ONLINE_SSID
	TARGET_SSID=$OFFLINE_SSID
else # TQ is between LOWER_LIMIT and UPPER_LIMIT
	echo "TQ is $GATEWAY_TQ, do nothing"
	exit 0
fi

HUP_NEEDED=0
for HOSTAPD in /var/run/hostapd-phy*; do # check status for all physical devices
	[ -f "$HOSTAPD" ] || continue
	if grep -qxF "ssid=$TARGET_SSID" "$HOSTAPD"; then
		echo "SSID $TARGET_SSID in $HOSTAPD is correct, nothing to do"
	elif grep -qxF "ssid=$CURRENT_SSID" "$HOSTAPD"; then
		logger -s -t "gluon-offline-ssid" -p 5 "TQ is $GATEWAY_TQ, SSID is $CURRENT_SSID, change to $TARGET_SSID" # write info to syslog
		sed -i "s/^ssid=$(sed_regex "$CURRENT_SSID")\$/ssid=$(sed_replacement "$TARGET_SSID")/" "$HOSTAPD"
		HUP_NEEDED=1 # HUP here would be too early for dualband devices
	else
		echo "Something is wrong, did not find SSID $ONLINE_SSID or $OFFLINE_SSID in $HOSTAPD"
	fi
done

if [ "$HUP_NEEDED" -eq 1 ]; then
	#killall -HUP hostapd # send HUP to all hostapd to load new SSID
	ubus call hostapd reload #HUPs dont work anymore so reload
	echo "HUP!"
fi
