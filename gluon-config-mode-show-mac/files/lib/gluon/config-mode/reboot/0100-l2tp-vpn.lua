local uci = require("simple-uci").cursor()
local lutil = require 'gluon.web.util'
local util = require 'gluon.util'
local site = require 'gluon.site_config'
local sysconfig = require 'gluon.sysconfig'
local pretty_hostname = require 'pretty_hostname'

local macaddr = uci:get_first('tunneldigger', 'broker', 'uuid')
local hostname = pretty_hostname.get(uci)
local msg = _translate('gluon-config-mode:macaddr')

renderer.render_string(msg, {
   macaddr = macaddr,
   hostname = hostname,
   site = site,
   sysconfig = sysconfig
})
