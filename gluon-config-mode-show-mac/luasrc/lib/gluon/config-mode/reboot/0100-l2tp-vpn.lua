local site_i18n = i18n 'gluon-site'
local uci = require("simple-uci").cursor()

local site = require 'gluon.site_config'
local sysconfig = require 'gluon.sysconfig'
local pretty_hostname = require 'pretty_hostname'

local macaddr = uci:get_first('tunneldigger', 'broker', 'uuid')
local hostname = pretty_hostname.get(uci)

local msg = site_i18n._translate('gluon-config-mode:macaddr')
if not msg then return end

renderer.render_string(msg, {
   macaddr = macaddr,
   hostname = hostname,
   site = site,
   sysconfig = sysconfig
})
