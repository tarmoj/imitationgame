// WEBSOCKET FUNCTIONS -----------------------------------
	
	//var serverURL = "ws://johannes.homeip.net:8008/ws";
	
	function doConnect()
	{
		websocket = new WebSocket(document.myform.url.value);
		websocket.onopen = function(evt) { onOpen(evt) };
		websocket.onclose = function(evt) { onClose(evt) };
		websocket.onmessage = function(evt) { onMessage(evt) };
		websocket.onerror = function(evt) { onError(evt) };
		
	}

	function onOpen(evt)
	{
		writeToScreen("connected\n");
		document.myform.connectButton.disabled = true;
		//document.myform.sendButton.disabled = false;
	}

	function onClose(evt)
	{
		writeToScreen("state: disconnected\n");
		document.myform.connectButton.disabled = false;
		//document.myform.sendButton.disabled = true;
	}

	

	function onError(evt)
	{
		writeToScreen('error (' + document.myform.url.value + ') ' + evt.data + '\n');
		websocket.close();
		connectButton.disabled = false;
		//document.myform.sendButton.disabled = true;
	}

	function doSend(message)
	{
		// how to check if websocket is open?
		if (websocket.readyState == 1) {
			websocket.send(message);
			writeToScreen("sent: " + message + '\n');
		} else 
			writeToScreen("WebSocket is not open!");
	}
	
	function doSendArray(arr) // the data must be an array of the type that the server knows to expect
	{
		if (websocket.readyState == 1) {
			//var arr = new Float64Array(data); // to convert for any case
			websocket.send(arr);
			writeToScreen("sent " + arr.length*arr.BYTES_PER_ELEMENT + 'bytes \n');
		} else 
			writeToScreen("WebSocket is not open!");
	}
	
	function doSendNumber(number) // UNTESTED!
	{
		if (websocket.readyState == 1) {
			var arr = new Float64Array([number]);
			websocket.send(new Float64Array([number]));
			writeToScreen("sent " + arr.length*arr.BYTES_PER_ELEMENT + 'bytes \n');
		} else 
			writeToScreen("WebSocket is not open!");
	}

	
	function writeToScreen(message)
	{
	//alert(message);
	var outputtext = document.getElementById("outputtext");
	outputtext.value += message;
	outputtext.scrollTop = outputtext.scrollHeight;
	}