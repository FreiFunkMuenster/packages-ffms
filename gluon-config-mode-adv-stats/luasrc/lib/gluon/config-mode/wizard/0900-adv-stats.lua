return function(form, uci)
	local pkg_i18n = i18n 'gluon-config-mode-adv-stats'

	local msg = pkg_i18n.translate(
		'Here you can enable advanced statistics for your node on'
		'https://grafana.freifunk-muensterland.de'
	)

	local s = form:section(Section, nil, msg)

	local o

	local advstats = s:option(Flag, "advstats", pkg_i18n.translate("Save extended node statistics"))
	advstats.default = uci:get_bool("advstats", "settings", "enabled")
	function advstats:write(data)
		uci:set("advstats", "settings", "enabled", data)
	end

	return {'advstats'}
end
