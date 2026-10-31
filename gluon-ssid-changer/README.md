ssid-changer
============

Script to change the SSID when there is no sufficient connection to the selected gateway.

Every minute the TQ of the currently used batman-adv gateway is checked:

* TQ below 45: the client SSID is replaced by `FF_OFFLINE_<nodename>` (shortened if necessary)
* TQ above 55: the client SSID from `wireless.client_radio0.ssid` is restored
* in between nothing is changed to prevent toggling

Only lines of the hostapd configuration that contain exactly the client SSID are changed, other
networks (e.g. a private WLAN) are not touched.
