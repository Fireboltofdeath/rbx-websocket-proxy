local BotToken = "";
local GameName = "Roblox";




----------------------------------------------------


local WS = require(workspace.WebSocket);
WS.Setup("http://127.0.0.1", 2030);
local Heartbeat = 0;

local OPCodes = {
	["1"] = function() -- Heartbeat
		WS.Send('{"op": 1, "d": null}');
	end,
	["2"] = function() -- Identify
		WS.Send(game:GetService('HttpService'):JSONEncode({
			op = 2,
			d = {
				token = "Bot " .. BotToken,
				properties = {
					["$os"] = "windows",
					["$browser"] = "roblox",
					["$device"] = "roblox"
				},
				
				presence = {
					status = "online",
					game = {
						name = GameName,
						type = 0
					}
				}
			}
		}))
	end,
}

WS.onopen = function()
	print'Discord Bot started.'
end

WS.onclose = function()
	print'Closed'
end

WS.onmessage = function(...)
	local Decoded = game:GetService('HttpService'):JSONDecode(...);
	
	local Event = Decoded.t;
	local Data = Decoded.d;
	
	if (Decoded.op == 10) then -- Hello payload
		
		Heartbeat = Decoded.d.heartbeat_interval / 1000;
		
	elseif (Decoded.op == 1) then -- Heartbeat request
			
		OPCodes["1"]();
		
	elseif (Event == "MESSAGE_CREATE") then
		
		print(Data.author.username .. "#" .. Data.author.discriminator .. ": " .. Data.content);
		
	end
	
end

if (WS.IsConnected()) then
	WS.Disconnect();
end

WS.StartListen(1);



WS.Connect("wss://gateway.discord.gg");

OPCodes['2']();

spawn(function()
	while wait() do
		if (Heartbeat == 0) then
			wait(.1);
		else
			wait(Heartbeat);
			OPCodes["1"]();
		end
	end
end)
