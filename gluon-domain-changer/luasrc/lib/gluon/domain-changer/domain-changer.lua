#!/usr/bin/lua

local uci = require('simple-uci').cursor()
local json = require 'jsonc'

local mac = (uci:get('network', 'client', 'macaddr') or ''):gsub(':', '')
local location = uci:get_first('gluon-node-info', 'location')
local uci_domain_changer = uci:get_first("gluon-domain-changer", "domain-changer")
local remote_url = uci:get('gluon-domain-changer', uci_domain_changer, 'url')
local current_domain = uci:get('gluon', 'core', 'domain')

local function log(msg)
	print(tostring(msg))
	os.execute(string.format('logger -t dom-changer "%s"', tostring(msg)))
end

local function sleep(seconds)
	log(string.format('Sleeping for %s seconds', seconds))
	os.execute("sleep " .. tonumber(seconds))
end

local function change_domain(new_domain)
	if new_domain and new_domain ~= current_domain then
		local cmd = 'gluon-switch-domain ' .. new_domain
		log('Running command "' .. cmd .. '"')
		os.execute(cmd)
		return true
	end
	return false
end

local function change_location_field(field, new_value)
	local current_value = uci:get('gluon-node-info', location, field)
	if current_value == nil then
		log('Creating ' .. field .. ' with value ' .. tostring(new_value))
		uci:set('gluon-node-info', location, field, new_value)
		return true
	end

	-- Für share_location als Boolean behandeln
	if field == "share_location" then
		local current_bool = uci:get_bool('gluon-node-info', location, field)
		if current_bool == nil then
			log('Could not read current share_location')
			return false
		elseif current_bool ~= new_value then
			uci:set('gluon-node-info', location, field, new_value)
			log(string.format('Changing %s from "%s" to "%s"', field, tostring(current_bool), tostring(new_value)))
			return true
		end
	else
		-- Bei lat/lng als Zahlen vergleichen
		local current_num = tonumber(current_value)
		if current_num ~= tonumber(new_value) then
			uci:set('gluon-node-info', location, field, new_value)
			log(string.format('Changing %s from "%s" to "%s"', field, tostring(current_value), tostring(new_value)))
			return true
		end
	end
	return false
end

if remote_url then
	local domain_number = tonumber(string.match(current_domain or "", "%d+")) or 0
	sleep(domain_number * 10)

	local fetch_cmd = string.format('uclient-fetch %s -q -O /tmp/node_provisioning.json', remote_url)
	os.execute(fetch_cmd)

	local provisioning = assert(json.load("/tmp/node_provisioning.json"))

	if provisioning[mac] then
		log("Found node provisioning entry for mac " .. mac)
		for k, v in pairs(provisioning[mac]) do
			if k == "target_domain" then
				change_domain(v)
			elseif k == "location_lat" then
				if change_location_field('latitude', tonumber(v)) then uci:commit('gluon-node-info') end
			elseif k == "location_lng" then
				if change_location_field('longitude', tonumber(v)) then uci:commit('gluon-node-info') end
			elseif k == "location_enabled" then
				if change_location_field('share_location', v) then uci:commit('gluon-node-info') end
			end
		end
	else
		log("No provisioning entry found for mac " .. mac)
	end
else
	log("Remote URL not set in uci")
end
