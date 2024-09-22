#!/usr/bin/lua

local uci = require('simple-uci').cursor()
local json = require 'jsonc'
local mac = uci:get('network', 'client', 'macaddr'):gsub(':', '')
local location = uci:get_first('gluon-node-info', 'location')
local remote_url = uci:get('gluon-domain-changer','settings', 'url')

local function log(msg)
	os.execute(string.format('logger -t dom-changer "%s"', tostring(msg)))
	print(tostring(msg))
end

local function change_domain(new_domain)
	local current_domain = uci:get('gluon', 'core', 'domain')
	if current_domain == nil then
		log('Could not read current domain. Maybe not multidomain Firmware?')
		return false
	elseif not current_domain == new_domain then
		local change_command = string.format('gluon-switch-domain %s', new_domain)
		log(string.format('Running command "%s"',change_command))
		os.execute(change_command)
		return true
	end
	return false
end

local function change_location_lat(new_loc_lat)
	local current_lat = uci:get('gluon-node-info', location, 'latitude')
	if current_lat == nil then
		log('Could not read current latitude location. Going to create it now!')
		uci:set('gluon-node-info', location, 'latitude', new_loc_lat)
		return true
	elseif not current_lat == new_loc_lat then
		uci:set('gluon-node-info', location, 'latitude', new_loc_lat)
		log(string.format('Changing uci-setting gluon-node-info.location.latitude from value "%f" to "%f"',current_lat,new_loc_lat))
		return true
	end
	return false
end

local function change_location_lng(new_loc_lng)
	local current_lng = uci:get('gluon-node-info', location, 'longitude')
	if current_lng == nil then
		log('Could not read current longitude location. Going to create it now!')
		uci:set('gluon-node-info', location, 'longitude', new_loc_lng)
		return true
	elseif not current_lng == new_loc_lng then
		uci:set('gluon-node-info', location, 'longitude', new_loc_lng)
		log(string.format('Changing uci-setting gluon-node-info.location.longitude from value "%f" to "%f"',current_lng,new_loc_lng))
		return true
	end
	return false
end

local function change_location_enabled(new_loc_enabled)
	local current_loc_enabled = uci:get_bool('gluon-node-info', location, 'share_location')
	if current_loc_enabled == nil then
		log('Could not read current location enabled.')
		return false
	elseif not current_loc_enabled == new_loc_enabled then
		uci:set('gluon-node-info', location, 'share_location', new_loc_enabled)
		log(string.format('Changing uci-setting gluon-node-info.location.share_location from value "%s" to "%s"',tostring(current_loc_enabled),tostring(new_loc_enabled)))
		return true
	end
	return false
end

if remote_url ~= nil then
	os.execute(string.format('uclient-fetch %s -q -O /tmp/node_provisioning.json',remote_url))
	local parsed_node_provisioning = assert(json.load("/tmp/node_provisioning.json"))
	for k, v in pairs(parsed_node_provisioning) do
		if k == mac then
			log(string.format("Found node provisioning entry for mac %s",mac))
			for setting_key, setting_value in pairs(v) do
				if setting_key == "target_domain" then
					change_domain(setting_value)
				elseif setting_key == "location_lat" then
					if change_location_lat(tonumber(setting_value)) then
						uci:commit('gluon-node-info')
					end
				elseif setting_key == "location_lng" then
					if change_location_lng(tonumber(setting_value)) then
						uci:commit('gluon-node-info')
					end
				elseif setting_key == "location_enabled" then
					if change_location_enabled(setting_value) then
						uci:commit('gluon-node-info')
					end
				end
			end
		end
	end
else
	log("remote url isn't set in uci")
end
