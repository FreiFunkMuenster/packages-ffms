obsolete({'eol_wifi_ssid'}, 'Use eol_ssid.ssid instead.')
if need_boolean({'eol_ssid', 'enabled'}, false) then
	need_boolean({'eol_ssid', 'as_additional_ssid', true})
	need_string({'eol_ssid', 'ssid'})
end
