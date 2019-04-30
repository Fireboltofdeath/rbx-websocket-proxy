# Roblox Module API

All functions will return
bool Success, variant error_or_data
unless otherwise specified. If Success is false, error_or_data will always be the error message.

##### function API.Setup(string Host, int PORT[, string Authentication])
Host should be the location of your server without any trailing slashes. EX: http://my.ip.or.domain

Port should be the port you specified in your server.

Authentication should only be specified if there is a password set in the server.

##### function API.IsConnected()
Returns true or false, if the WebSocket proxy is already connected to a WebSocket server.

##### function API.GetConnection()
Returns the url that the WebSocket proxy is already connected to, or false if it isn't connected.

##### function API.Connect(string Server)
Connect to a WebSocket Server, unless already connected to one.


##### function API.Disconnect()
Disconnect from the current WebSocket Server, unless not connected to one.

##### function API.Ping()
Prevent server from disconnecting if you do not send any requests to the server in a while.



#### Events

##### function API.StartListen(int Interval)
This will start the actual WebSocket listener, this will make a request to the server every Interval seconds to get any new data that has been sent to you. Events will not be called without this. You should call this before connecting to the server.
