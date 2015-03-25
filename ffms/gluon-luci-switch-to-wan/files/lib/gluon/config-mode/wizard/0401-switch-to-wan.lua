#!/usr/bin/lua

local cbi = require "luci.cbi"
local uci = luci.model.uci.cursor()

local M = {}

function M.section(form)
  local s = form:section(cbi.SimpleSection, nil,
    [[Hier kannst du festlegen, ob die Switchports deines Knotens 
    mit der WAN-Schnittstelle überbrückt werden sollen, damit Geräte,
    die an Diesen angeschlossen sind, dein privates Netzwerk, statt 
    dem Freifunk Netz bekommen.]])
   
  local o
  o = s:option(cbi.Flag, "_switch_to_wan", "Switch mit WAN-Schnittstelle brücken")
  o.default = uci:get("network", "wan", "ifname") == "eth0 eth1"
  o.rmempty = false
end
  
function M.handle(data)
  if data._switch_to_wan then
    uci:set("network", "client", "ifname", "bat0")
    uci:set("network", "wan", "ifname", "eth0 eth1")
  else
    uci:set("network", "client", "ifname", "bat0 eth0")
    uci:set("network", "wan", "ifname", "eth1")
  end
  uci:save("network")
  uci:commit("network")
end