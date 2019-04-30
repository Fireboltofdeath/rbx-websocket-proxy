-- This should be placed into a ModuleScript.

local API = {
	Config = {},
};
local placeholder = function()end;

-- // Events //
API.onopen = placeholder;
API.onclose = placeholder;
API.onmessage = placeholder;

local jsonDecode = function(...) return game:GetService('HttpService'):JSONDecode(...); end;
local jsonEncode = function(...) return game:GetService('HttpService'):JSONEncode(...); end;


function API.HttpRequest(Url, Method, Headers, Body)
	
	return game:GetService('HttpService'):RequestAsync({
		Url = Url,
		Method = Method or "GET",
		Headers = Headers,
		Body = Body
	})
	
end

function API.Request(Path, Method, Headers, Body)
	
	local Data = API.HttpRequest(API.Config.Host .. ":" .. API.Config.Port .. Path, Method, Headers or {
		Authentication = API.Config.Authentication
	}, Body).Body;
	return jsonDecode(Data);
	
end

function API.Setup(Host, Port, Authentication)
	
	API.Config = {
		Host = Host,
		Port = Port,
		Authentication = Authentication
	}
	
end

function API.IsConnected()
	
	local data = API.Request("/connection/get");
	if (data.data == false) then
		
		return false;
		
	else
		
		return true;
		
	end
	
end

function API.GetConnection()
	
	return API.Request("/connection/get").data;
	
end

function API.Connect(Url)
	
	local data = API.Request("/connect/" .. game:GetService'HttpService':UrlEncode(Url), "POST");
	if (data.success) then
		
		API.onopen();
		return true;
		
	else
		
		return false, data.reason;
		
	end
	
end

function API.Disconnect()
	
	local data = API.Request("/disconnect", "POST");
	if (data.success) then
		
		return true;
		
	else
		
		return false, data.reason;
		
	end
	
end

function API.Ping()
	
	return API.Request("/connection/ping", "POST").success;
	
end

function API.Send(message)
	
	local data = API.Request("/connection/send", "POST", {
		Authentication = API.Config.Authentication;
		["Content-Type"] = "application/json";
	}, jsonEncode{
		Content = message,
	});
	
	if (data.success) then
		
		return true
		
	else
		
		return false, data.reason;
		
	end
	
end

function API.GetMessages()
	
	local data = API.Request("/connection/messages");
	if (data.success) then
		
		return true, data.data;
		
	else
		
		return false, data.reason;
		
	end
	
end

-- // Listener //
local isListening = false;
local listenTime = .1;

function API.StartListen(Interval)
	
	listenTime = Interval or 1;
	isListening = true;
	
end

spawn (function()
	while wait(listenTime) do
		
		local Suc, Error = pcall(function()
			
			if (isListening) then
				
				local success, messages = API.GetMessages();
				
				if (success) then
					
					if (#messages > 0) then
						
						table.foreach(messages, function (_, msg) 
							API.onmessage(msg);
						end);
						
					end
					
				else
					
					API.onclose();
					isListening = false;
					
				end
				
			end
			
		end)
		
		if (not Suc) then
			
			warn("Error while executing WebSocket Listener", Error);
			wait(2);
			
		end
		
	end
end)

return API;
