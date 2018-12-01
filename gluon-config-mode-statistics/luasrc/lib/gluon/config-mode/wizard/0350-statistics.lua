return function(form, uci)
	local pkg_i18n = i18n 'gluon-config-mode-statistics'

	local msg = pkg_i18n.translate(
	        'If you activate this option, advanced statistics ' ..
	        'will be visualized on our grafana server.'
	)

	local s = form:section(Section, nil, msg)

	local advuci = uci:get_first("gluon-advanced-config", "advstats")

	local a = s:option(Flag, "advstats", pkg_i18n.translate("Track advanced statistics"))
	a.default=false
	if uci:get_bool("gluon-advanced-config", advuci, "enabled") == true then a.default=true end
	
	function a:write(data)
		uci:set("gluon-advanced-config", advuci , "enabled", data)
		uci:commit("gluon-advanced-config")
	end

	return {'advstats'}
end
