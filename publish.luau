--!strict
local net = require("@lune/net") :: any
local process = require("@lune/process") :: any
local stdio = require("@lune/stdio") :: any

local APIKey = assert(process.env.ROBLOX_API_KEY, 'missing "ROBLOX_API_KEY" environment variable')
local ROBLOSECURITY = assert(process.env.ROBLOSECURITY, 'missing "ROBLOSECURITY" environment variable')

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

local downloaded: { { name: string, placeId: string, data: string } } = {}

for _, place in places do
	local name = place.name
	local placeId = place.placeId

	stdio.write(`DOWNLOADING {name} ... `)

	local response = net.request({
		url = `https://assetdelivery.roblox.com/v1/asset/?id={placeId}`,
		method = "GET",
		headers = {
			["Cookie"] = `.ROBLOSECURITY={ROBLOSECURITY}`,
			["User-Agent"] = "Roblox/WinInet",
		},
	})

	if response.statusCode >= 200 and response.statusCode < 300 then
		print("DOWNLOADED!")
		table.insert(downloaded, { name = name, placeId = placeId, data = response.body })
	else
		warn(`SKIPPED {name}: HTTP {response.statusCode}: {response.body}`)
	end
end

for _, place in downloaded do
	stdio.write(`PUBLISHING {place.name} ... `)

	local response = net.request({
		url = `https://apis.roblox.com/universes/v1/4610122749/places/{place.placeId}/versions?versionType=Published`,
		method = "POST",
		headers = {
			["x-api-key"] = APIKey,
			["Content-Type"] = "application/octet-stream",
		},
		body = place.data,
	})

	if response.statusCode >= 200 and response.statusCode < 300 then
		print("PUBLISHED!")
	else
		error(`FAILED! HTTP {response.statusCode}: {response.body}`)
	end
end

print(`\nDONE! {#downloaded}/{#places} place(s) published.`)