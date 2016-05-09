uart_none, uart_init, uart_conn = 0, 1, 2
uart_state = uart_none

function uart_hdl(data)
	if (uart_state == uart_none) then
		if (data == 0x80) then
			uart_state = uart_init
			uart.write(0, 0xA1)
		end
	elseif (uart_state == uart_init) then
		uart_state = uart_conn
	end
end

function serial_init()
	uart.alt(1)
	uart.setup(0, 2400, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
	uart.on("data", 0, uart_hdl, 0)
end

function serial_settag()
	uart.write(0, 0x81)
	uart.write(0, 0x00)
	tmr.delay(20000)
	uart.write(0, 0x80)
	uart.write(0, 0x00)
end

function dostuff(conn,payload)
	if uart_state == uart_none then
		conn:send("not initialised")
		uart.write(0, 0x00)
	elseif uart_state == uart_init then
		conn:send("initialized")
		uart_state = uart_conn
	elseif 	uart_state == uart_conn then
		conn:send("Marker gesetzt")
		serial_settag()
	end
end

function handlecon(conn)
	conn:on("receive", dostuff)
	conn:on("sent", function(conn) conn:close() end)
end

wifi.setmode(wifi.SOFTAP)
wifi.ap.config({ssid="H4N", pwd="12345678"})
wifi.ap.dhcp.start()

srv=net.createServer(net.TCP)
srv:listen(80, handlecon)
serial_init()
