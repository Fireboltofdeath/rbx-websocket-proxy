local WS = require(workspace.WebSocket);

local Heartbeat = 0;

local function doHeartbeat()
	WS.Send(game:GetService('HttpService'):JSONEncode({
		op = 11;
	}));
end

WS.Setup("http://127.0.0.1", 2030);

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
		
	elseif (Decoded.op == 11) then -- Heartbeat request
		
		doHeartbeat();
		
	elseif (Event == "MESSAGE_CREATE") then
		print(Data.author.username .. "#" .. Data.author.discriminator .. ": " .. Data.content);
	end
	
end

if (WS.IsConnected()) then
	WS.Disconnect();
end

WS.StartListen(1);



WS.Connect("wss://gateway.discord.gg");

WS.Send(game:GetService('HttpService'):JSONEncode({
	op = 2,
	d = {
		token = "Bot TOKEN",
    
		properties = {
			["$os"] = "windows",
			["$browser"] = "roblox",
			["$device"] = "roblox"
		},
		
		presence = {
			status = "online",
			game = {
				name = "Run from Roblox"
			}
		}
	}
}))

spawn(function()
	while wait() do
		if (Heartbeat == 0) then
			wait(.1);
		else
			wait(Heartbeat);
			doHeartbeat();
		end
	end
end)
