#!/usr/bin/lua

-- Manifest-Format (angelehnt an das Manifest des Autoupdaters):
--
--   SERIAL=1759240000
--
--   # node-id;location_lat;location_lng;location_enabled;target_domain
--   f4f26d123456;51.9624;7.6257;1;dom2
--   ---
--   <ECDSA-Signatur des Teils oberhalb von ---, eine pro Zeile>

local uci = require('simple-uci').cursor()
local util = require('gluon.util')

local CONFIG = 'gluon-domain-changer'
local MANIFEST_FILE = '/tmp/domain-changer.manifest'
local PID_FILE = '/var/run/domain-changer.pid'
local SERIAL_FILE = '/var/run/domain-changer.serial'
local MAX_DELAY = 600
local MAX_SIZE = 1024 * 1024

local node_id = util.node_id()
local section = uci:get_first(CONFIG, 'domain-changer')
local remote_url = uci:get(CONFIG, section, 'url')
local pubkeys = uci:get_list(CONFIG, section, 'pubkey')
local good_signatures = tonumber(uci:get(CONFIG, section, 'good_signatures')) or 1
local stored_serial = tonumber(uci:get(CONFIG, section, 'serial')) or 0
local current_domain = uci:get('gluon', 'core', 'domain')

local function shell_quote(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- Meldungen sammeln und mit einem einzigen logger-Aufruf schreiben
local log_lines = {}

local function log(msg)
	print(tostring(msg))
	table.insert(log_lines, tostring(msg))
end

local function flush_log()
	if #log_lines == 0 then
		return
	end
	local p = io.popen('logger -t dom-changer', 'w')
	if p then
		p:write(table.concat(log_lines, '\n'), '\n')
		p:close()
	end
	log_lines = {}
end

local function read_pid(path)
	local f = io.open(path, 'r')
	if not f then
		return nil
	end
	local pid = f:read('*n')
	f:close()
	return pid
end

-- Die Serial liegt im RAM und wird nur in den Flash geschrieben, wenn der Knoten eine Aenderung uebernimmt.
-- So fuehrt eine neue Serial nicht auf allen Knoten zu einem Schreibzugriff auf den Flash.
local last_serial = math.max(stored_serial, read_pid(SERIAL_FILE) or 0)

local function already_running()
	local pid = read_pid(PID_FILE)
	if not pid then
		return false
	end
	local f = io.open('/proc/' .. pid .. '/cmdline', 'r')
	if not f then
		return false
	end
	local cmdline = f:read('*a')
	f:close()
	return cmdline:find('domain-changer', 1, true) ~= nil
end

local function finish(code)
	os.remove(MANIFEST_FILE)
	os.remove(PID_FILE)
	flush_log()
	os.exit(code)
end

local function sleep(seconds)
	log(string.format('Sleeping for %d seconds', seconds))
	flush_log()
	os.execute('sleep ' .. tonumber(seconds))
end

local function split(line)
	local fields = {}
	for field in (line .. ';'):gmatch('([^;]*);') do
		table.insert(fields, (field:gsub('^%s+', ''):gsub('%s+$', '')))
	end
	return fields
end

-- Laedt das Manifest und schreibt den signierten Teil nach MANIFEST_FILE.
-- Bricht den Download ab, sobald feststeht, dass SERIAL nicht neuer ist.
local function fetch_manifest()
	local manifest = { signatures = {} }
	local out = io.open(MANIFEST_FILE, 'w')
	if not out then
		return nil, 'Could not open ' .. MANIFEST_FILE
	end
	local p = io.popen('uclient-fetch -q -O - ' .. shell_quote(remote_url), 'r')

	local size, signed_part, err = 0, true, nil
	for line in p:lines() do
		size = size + #line + 1
		if size > MAX_SIZE then
			err = 'Manifest exceeds ' .. MAX_SIZE .. ' bytes'
			break
		end

		if not signed_part then
			local sig = line:match('^%s*(%x+)%s*$')
			if sig and #sig == 128 then
				table.insert(manifest.signatures, sig)
			end
		elseif line == '---' then
			signed_part = false
		else
			out:write(line, '\n')

			local key, value = line:match('^([%u_]+)=(.*)$')
			if key == 'SERIAL' then
				manifest.serial = tonumber(value)
				if not manifest.serial then
					err = 'Invalid SERIAL "' .. value .. '"'
					break
				elseif manifest.serial <= last_serial then
					manifest.unchanged = true
					break
				end
			elseif not key and not line:match('^%s*#') and line:find(';', 1, true) then
				if not manifest.serial then
					err = 'SERIAL must be set before the first entry'
					break
				end
				local fields = split(line)
				if fields[1]:gsub(':', ''):lower() == node_id then
					manifest.entry = fields
				end
			end
		end
	end
	p:close()
	out:close()

	if err then
		return nil, err
	elseif manifest.unchanged then
		return manifest
	elseif signed_part then
		return nil, 'Download of manifest from ' .. remote_url .. ' failed or was incomplete'
	elseif not manifest.serial then
		return nil, 'Manifest has no SERIAL'
	end
	return manifest
end

local function verify_signatures(signatures)
	local args = {}
	for _, sig in ipairs(signatures) do
		table.insert(args, '-s ' .. sig)
	end
	for _, key in ipairs(pubkeys) do
		if key:match('^%x+$') and #key == 64 then
			table.insert(args, '-p ' .. key)
		end
	end

	local cmd = string.format('ecdsaverify -n %d %s %s', good_signatures, table.concat(args, ' '), MANIFEST_FILE)
	return os.execute(cmd) == 0
end

local function to_coordinate(value, limit)
	local num = tonumber(value)
	if num and num >= -limit and num <= limit then
		return num
	end
	return nil
end

local function to_bool(value)
	if value == '1' or value == 'true' then
		return true
	elseif value == '0' or value == 'false' then
		return false
	end
	return nil
end

local function get_location()
	return uci:get_first('gluon-node-info', 'location') or uci:add('gluon-node-info', 'location')
end

-- Koordinaten auf 6 Nachkommastellen (ca. 10 cm) vergleichen
local function set_coordinate(location, field, new_value)
	if new_value == nil then
		return false
	end
	local current_value = tonumber(uci:get('gluon-node-info', location, field))
	if current_value and string.format('%.6f', current_value) == string.format('%.6f', new_value) then
		return false
	end
	log(string.format('Changing %s from "%s" to "%s"', field, tostring(current_value), tostring(new_value)))
	uci:set('gluon-node-info', location, field, new_value)
	return true
end

local function set_share_location(location, new_value)
	if new_value == nil or uci:get_bool('gluon-node-info', location, 'share_location') == new_value then
		return false
	end
	log(string.format('Changing share_location to "%s"', tostring(new_value)))
	uci:set('gluon-node-info', location, 'share_location', new_value)
	return true
end

local function apply_location(entry)
	local location = get_location()
	local changed = false
	if set_coordinate(location, 'latitude', to_coordinate(entry[2], 90)) then changed = true end
	if set_coordinate(location, 'longitude', to_coordinate(entry[3], 180)) then changed = true end
	if set_share_location(location, to_bool(entry[4])) then changed = true end
	if changed then
		uci:commit('gluon-node-info')
	end
	return changed
end

local function file_exists(path)
	local f = io.open(path, 'r')
	if f then
		f:close()
		return true
	end
	return false
end

local function valid_domain(new_domain)
	if not new_domain or new_domain == '' or new_domain == current_domain then
		return false
	end
	if not new_domain:match('^[%w_-]+$') or not file_exists('/lib/gluon/domains/' .. new_domain .. '.json') then
		log('Ignoring unknown domain "' .. new_domain .. '"')
		return false
	end
	return true
end

local function store_serial(serial, persist)
	local f = io.open(SERIAL_FILE, 'w')
	if f then
		f:write(tostring(serial), '\n')
		f:close()
	end
	if persist and serial ~= stored_serial then
		uci:set(CONFIG, section, 'serial', serial)
		uci:commit(CONFIG)
	end
end

if not remote_url then
	log('Remote URL not set in uci')
	flush_log()
	os.exit(0)
end

if #pubkeys == 0 then
	log('No public keys set in uci, refusing to apply unsigned provisioning data')
	flush_log()
	os.exit(1)
end

if already_running() then
	log('Another instance is already running')
	flush_log()
	os.exit(0)
end

local pid_file = io.open(PID_FILE, 'w')
if pid_file then
	pid_file:write(read_pid('/proc/self/stat') or '', '\n')
	pid_file:close()
end

-- Anfragen der Knoten ueber MAX_DELAY Sekunden verteilen (aus der Knoten-ID abgeleitet)
sleep((tonumber(node_id:sub(-4), 16) or 0) % MAX_DELAY)

local manifest, err = fetch_manifest()
if not manifest then
	log(err)
	finish(1)
end

if manifest.unchanged then
	log(string.format('Manifest serial %s is not newer than %s, nothing to do', manifest.serial, last_serial))
	finish(0)
end

if not verify_signatures(manifest.signatures) then
	log('Signature check of manifest failed')
	finish(1)
end

log(string.format('Manifest serial %s verified', manifest.serial))

local new_domain = nil
local location_changed = false
if manifest.entry then
	log('Found provisioning entry for node ' .. node_id)
	-- Standort zuerst setzen, da der Domainwechsel einen Reboot ausloest
	location_changed = apply_location(manifest.entry)
	if valid_domain(manifest.entry[5]) then
		new_domain = manifest.entry[5]
	end
else
	log('No provisioning entry found for node ' .. node_id)
end

store_serial(manifest.serial, location_changed or new_domain ~= nil)

if new_domain then
	-- gluon-switch-domain setzt die Domain und startet den Knoten neu, der Wechsel erfolgt beim Booten
	log(string.format('Switching domain from "%s" to "%s"', tostring(current_domain), new_domain))
	os.remove(MANIFEST_FILE)
	os.remove(PID_FILE)
	flush_log()
	os.execute('gluon-switch-domain ' .. new_domain)
	log('gluon-switch-domain failed')
	finish(1)
end

finish(0)
