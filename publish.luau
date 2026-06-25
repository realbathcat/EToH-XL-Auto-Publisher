--!strict
local net = require("@lune/net") :: any
local process = require("@lune/process") :: any
local stdio = require("@lune/stdio") :: any
local serde = require("@lune/serde") :: any
local task = require("@lune/task") :: any

local api = assert(process.env.ROBLOX_API_KEY, 'missing "ROBLOX_API_KEY" environment variable')

local id = "4610122749"
local places = {
	-- EToH XL
	{ name = "Ring Select", placeId = "13218032675" },

	-- Rings
	{ name = "Ring 1", placeId = "13228556826" },
	{ name = "Ring 2", placeId = "13333937540" },
	{ name = "Ring 3", placeId = "13654432865" },
	{ name = "Ring 4", placeId = "14824811256" },
	{ name = "Ring 5", placeId = "80018210783565" },

	-- Ring Subrealms
	{ name = "Forgotten Ridge", placeId = "14824810790" },
	{ name = "Event Realm", placeId = "13618997258" },

	-- Zones
	{ name = "Zone 1", placeId = "18768674545" },

	-- Events
	{ name = "Ring 1: Legacy", placeId = "135909633024435" },
	{ name = "Ring 2: Legacy", placeId = "135930050970103" },

	{ name = "1 Million Visits Event", placeId = "78686711727244" },
	{ name = "Awesome Land", placeId = "124350462948914" },
	{ name = "Bridge World", placeId = "16620863521" },
	{ name = "Defend the Citadels", placeId = "106214650290927" },

	{ name = "Spring Isles", placeId = "126419488496085" },
	{ name = "Evercrescent Mountain", placeId = "16067567346" },
}

local downloaded = {}
local failed = {}

local function request(opts: any, context: string): any
	for attempt = 1, 5 do
		local ok, result = pcall(net.request, opts)

		if not ok then
			warn(`{context}: request error (attempt {attempt}/{5}): {result}`)
			task.wait(2 ^ attempt)
			continue
		end

		local response = result :: any

		if response.statusCode == 429 then
			local retryAfter = tonumber(response.headers and response.headers["retry-after"]) or (2 ^ attempt)
			warn(`{context}: rate limited, waiting {retryAfter}s (attempt {attempt}/{5})`)
			task.wait(retryAfter)
			continue
		end

		return response
	end

	return nil
end

for _, place in places do
	local name = place.name
	local placeId = place.placeId

	stdio.write(`DOWNLOADING {name} ... - `)

	local response = request({
		url = `https://apis.roblox.com/asset-delivery-api/v1/assetId/{placeId}`,
		method = "GET",
		headers = {
			["x-api-key"] = api,
		},
	}, `download:{name}`)

	if response == nil then
		print("SKIPPED!")
		table.insert(failed, { name = name, placeId = placeId, stage = "download", reason = "exhausted retries (location request)" })
		continue
	end

	if response.statusCode < 200 or response.statusCode >= 300 then
		print("SKIPPED!")
		warn(`SKIPPED {name}: HTTP {response.statusCode}: {response.body}`)
		table.insert(failed, { name = name, placeId = placeId, stage = "download", reason = `HTTP {response.statusCode} on location request` })
		continue
	end

	local decode, data = pcall(function()
		return serde.decode("json", response.body)
	end)

	local cdn: string? = nil
	if decode and typeof(data) == "table" then
		if typeof(data.location) == "string" then
			cdn = data.location
		elseif typeof(data.locations) == "table" then
			local locations = data.locations :: {any}
			local first = locations[1]

			if typeof(first) == "table" and typeof(first.location) == "string" then
				cdn = first.location
			end
		end
	end

	if cdn == nil then
		print("SKIPPED!")
		warn(`SKIPPED {name}: unexpected location response body: {response.body}`)
		table.insert(failed, { name = name, placeId = placeId, stage = "download", reason = "could not find a CDN location in the response" })
		continue
	end

	local response = request({
		url = cdn,
		method = "GET",
	}, `download-cdn:{name}`)

	if response == nil or response.statusCode < 200 or response.statusCode >= 300 then
		local statusText = if response then tostring(response.statusCode) else "no response"
		print("SKIPPED!")
		warn(`SKIPPED {name}: failed to fetch binary from CDN (status: {statusText})`)
		table.insert(failed, { name = name, placeId = placeId, stage = "download", reason = "CDN fetch failed" })
		continue
	end

	local character = (response.body:match("^%s*(.-)%s*$") or response.body):sub(1, 1)
	if #response.body < 1024 or character == "{" or character == "[" then
		print("SKIPPED!")
		warn(`SKIPPED {name}: downloaded body doesn't look like a place file ({#response.body} bytes)`)
		table.insert(failed, {
			name = name,
			placeId = placeId,
			stage = "download",
			reason = "suspicious response body",
		})
		continue
	end

	print("DOWNLOADED!")
	table.insert(downloaded, { name = name, placeId = placeId, data = response.body })
	task.wait(3)
end

local count = 0
for _, place in downloaded do
	stdio.write(`PUBLISHING {place.name} ... - `)

	local response = request({
		url = `https://apis.roblox.com/universes/v1/{id}/places/{place.placeId}/versions?versionType=Published`,
		method = "POST",
		headers = {
			["x-api-key"] = api,
			["Content-Type"] = "application/octet-stream",
		},
		body = place.data,
	}, `publish:{place.name}`)

	if response == nil then
		print("FAILED!")
		table.insert(failed, { name = place.name, placeId = place.placeId, stage = "publish", reason = "exhausted retries" })
		continue
	end

	if response.statusCode < 200 or response.statusCode >= 300 then
		print("FAILED!")
		warn(`FAILED {place.name}: HTTP {response.statusCode}: {response.body}`)
		table.insert(failed, { name = place.name, placeId = place.placeId, stage = "publish", reason = `HTTP {response.statusCode}` })
		continue
	end

	local success, result = pcall(function()
		return serde.decode("json", response.body)
	end)

	if success and typeof(result) == "table" and result.versionNumber ~= nil then
		print(`PUBLISHED! (v{result.versionNumber})`)
	else
		print("PUBLISHED!")
	end

	count += 1
	task.wait(3)
end

print(`\nDONE! {count}/{#places} place(s) published.`)

if #failed > 0 then
	print(`\n{#failed} failure(s):`)
	for _, f in failed do
		print(`  - [{f.stage}] {f.name} ({f.placeId}): {f.reason}`)
	end
	process.exit(1)
end
