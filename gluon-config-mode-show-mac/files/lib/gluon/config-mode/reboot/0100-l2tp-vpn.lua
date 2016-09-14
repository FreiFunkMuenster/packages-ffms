local uci = luci.model.uci.cursor()

local meshvpn_enabled = uci:get('tunneldigger', uci:get_first('tunneldigger', 'broker'), 'enabled')

local i18n = require 'luci.i18n'
local util = require 'luci.util'
local site = require 'gluon.site_config'
local sysconfig = require 'gluon.sysconfig'

local macaddr = uci:get_first('tunneldigger', 'broker', 'uuid')
local hostname = uci:get_first("system", "system", "hostname")
local msg = i18n.translate('gluon-config-mode:macaddr')

return function()
    luci.template.render_string(msg, {
        macaddr = macaddr,
        hostname = hostname,
        site = site,
        sysconfig = sysconfig
    })
end
