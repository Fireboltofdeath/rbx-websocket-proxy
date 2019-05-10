/* Config */
var Port = 2030; // This can be changed to any port you'd like.

var IdleTimeout = 2; // Defines how long (in minutes) it will take to close the websocket after no activity from roblox.

var maxMessagesPerRecieve = 20; // Maximum amount of messages sent everytime Roblox requests it.

var Authentication = ""; // Blank is disabled, set to a password to prevent random people from accessing it.

var LongPollTimeout = 30; // How many seconds until long polling should reset the request?
/* End Config */

const WS = require('ws');
const colors = require('colors'); // Extends String's prototype to allow easy console colors.
const json = JSON.stringify;
const Emitter = new (require('events').EventEmitter)();
Emitter.setMaxListeners(5000000); // Allow as many servers as required to connect.

var WebSocket;
var Messages = [];
var SentMessages = [];
var PingDate = new Date(); // Used for checking if the WebSocket should close.

function startConnection(WebSock) {
	Messages.length = 0; // Don't want old messages.
	SentMessages.length = 0;
	
	WebSock.on("open", function() {
		console.log("Successfully started listening to websocket. ".green + WebSock.url);
	});

	WebSock.on("close", function( code, reason ) {
		console.log("Connection closed. " + WebSock.url + ("[ " + code + ", " + reason + "]").red);
		
		WebSocket = null;
		Emitter.emit("data");
	});
	
	WebSock.on("error", function( error ) {
		console.log("Connection error. ".red + error.toString().red);
		
		WebSocket = null;
		Emitter.emit("data");
	});
	
	WebSock.on("message", function( data ) {
		
		Messages.push( data ); // Push any new messages into the message array.
		Emitter.emit("data");
		
	});
}

function updatePing() {
	PingDate = new Date();
}
function checkPing() {
	return (new Date() - PingDate) > ( IdleTimeout * 60 * 1000);
}

function checkAuth( req, res ) {
	if (Authentication == "") {
		return true;
	}
	
	if ( req.header("Authentication") == Authentication ) {
		return true;
	};
	
	return false;
}
var authFailedMessage = json({
	success: false,
	reason: "Authentication failure."
});

/* Interface */
var express = require('express');
var app = express();

app.use(require("body-parser").json());

app.get("/", function( req, res ) {
	res.send("Firebolt's Websocket Proxy is running.");
});

app.use(function( req, res, next ) {
	if (!checkAuth( req, res )) {
		
		return res.send(authFailedMessage);
		
	}
	
	updatePing();
	next();
});

app.get("/connection/get", function( req, res ) {
	if (WebSocket) {
		
		return res.send(json({
			success: true,
			data: WebSocket.url,
		}));
		
	} else {
		
		return res.send(json({
			success: true,
			data: false
		}));
		
	}
});

app.get("/connection/messages", function( req, res ) {
	if (WebSocket) {
		
		var dataSent = false;
		
		function l() {
			dataSent = true;
			return res.send(json({
				success: true,
				data: Messages.splice(0, maxMessagesPerRecieve)
			}));
		}
		if (Messages.length > 0) return l();
		
		Emitter.once('data', l);
		setTimeout(function() {
			if (dataSent) return;
			
			Emitter.removeListener('data', l);
			
			return res.send(json({
				success: true,
				data: Messages.splice(0, maxMessagesPerRecieve)
			}));
			
		}, LongPollTimeout * 1000);
		
		
	} else {
		
		return res.send(json({
			success: false,
			reason: "WebSocket is not connected."
		}));
		
	}
});

app.post("/connect/:url", function( req, res ) { // Connect to service.


	if (WebSocket) {
		
		return res.send(json({
			success: false,
			reason: "A WebSocket is already connected."
		}));
		
	} else {
		
		WebSocket = new WS( req.params.url, {
			
		});
		startConnection(WebSocket);
		
		return res.send(json({
			success: true
		}));
		
	}
});
app.post("/disconnect", function( req, res ) {
	if (WebSocket) {
		
		WebSocket.close();
		
		return res.send(json({
			success: true
		}));
		
	} else {
		
		return res.send(json({
			success: false,
			reason: "WebSocket is not connected."
		}));
		
	}
});

app.post("/connection/ping", function( req, res ) { // Prevent timeout without affecting WebSocket, you could also request / instead.
	
	res.send(json({
		success: true
	}));
	
});

app.post("/connection/send", function( req, res ) {
	
	if (req.body) {
		
		if (req.body.Content) {
			
			SentMessages.push(req.body.Content);
			return res.send(json({
				success: true
			}));
			
		} else {
			
			return res.send(json({
				success: false,
				reason: "Message not specified."
			}));
			
		}
		
	} else {
		
		return res.send(json({
			success: false,
			reason: "Body not sent."
		}));
		
	}
	
});

app.listen(Port, () => {
	
	console.log( ("WebSocket Proxy listening on Port " + Port).blue );
	
});

/* Utility */
setInterval(function() {
	
	if (WebSocket) {
		if (checkPing()) {
			
			WebSocket.close();
			
		}
	}
	
}, 1000 * 10); // Check if the WebSocket has been inactive longer than IdleTimeout.

setInterval(function() {
	
	if (WebSocket) {
		if (WebSocket.readyState == WebSocket.OPEN) {
			if (SentMessages.length > 0) {
				WebSocket.send( SentMessages.splice(0,1)[0] );
			}
		}
	}
	
}, 100); // Send any requested message every 100 ms
