return function(form, uci)
	local pkg_i18n = i18n 'gluon-config-mode-statistics'

	local msg = pkg_i18n.translate(
	        'If you activate this option, advanced statistics ' ..
	        'will be visualized on our grafana server.'
	)
	local s = form:section(Section, nil, msg)
	if not uci:get_first("gluon-node-info", "advstats") then uci:add("gluon-node-info", "advstats") end
	local advuci = uci:get_first("gluon-node-info", "advstats")
	local advstats = s:option(Flag, "advstats", pkg_i18n.translate("Track advanced statistics"))
	advstats.default = uci:get_bool("gluon-node-info", advuci, "advstats") or false
	function advstats:write(data)
		uci:set("gluon-node-info", advuci , "enabled", data)
	end

	return {'advstats'}
end
