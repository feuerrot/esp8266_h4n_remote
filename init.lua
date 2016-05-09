uart_none, uart_init, uart_conn = 0, 1, 2
uart_state = uart_none

last_data = 0

uartdatahandler = function(data)
	last_data = data
	if (uart_state == uart_none) then
		if (data == 0x80) then
			uart_state = uart_init
			uart.write(0, 0xA1)
		end
	elseif (uart_state == uart_init) then
		uart_state = uart_conn
	end
end

send_init = function()
	uart.write(0, 0x00)
	tmr.delay(1000000)
	uart.write(0, 0x00)
	tmr.delay(1000000)
	uart.write(0, 0x00)
	tmr.delay(1000000)
	uart.write(0, 0x00)
	tmr.delay(1000000)
	uart.write(0, 0x00)
	tmr.delay(1000000)
	uart.write(0, 0xA1)
end

serial_init = function()
	--uart.on("data", 1, uartdatahandler, 0)
	uart.setup(0, 2400, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
	uart.alt(1)
end

serial_settag = function()
	uart.write(0, 0x81)
	uart.write(0, 0x00)
	tmr.delay(10000)
	uart.write(0, 0x80)
	uart.write(0, 0x00)
end

dostuff = function(conn,payload)
	if uart_state == uart_none then
		conn:send("not initialised")
		--uart.write(0, 0x00)
		send_init()
		uart_state = uart_conn
	elseif uart_state == uart_init then
		conn:send("initialized")
		uart_state = uart_conn
	elseif 	uart_state == uart_conn then
		conn:send("Marker gesetzt")
		serial_settag()
	end
end

handlecon = function(conn)
	conn:on("receive", dostuff)
	conn:on("sent", function(conn) conn:close() end)
end

wifi.setmode(wifi.SOFTAP)
wifi.ap.config({ssid="H4N", pwd="12345678"})
wifi.ap.dhcp.start()


srv=net.createServer(net.TCP)
srv:listen(80, handlecon)


tmr.delay(5000000)
serial_init()


