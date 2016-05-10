connected = 0

function connect()
	if (connected == 0) then
		uart.write(0, 0x00)
		tmr.start(0)
	end
end	

function connect_d()
	tmr.register(0, 500, tmr.ALARM_SEMI, connect)
end

function uart_hdl(data)
	if (connected == 0) then
		uart.write(0, 0xA1)
		connected = 1
	end
end

function serial_init()
	uart.setup(0, 2400, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
	uart.alt(1)
	uart.on("data", 1, uart_hdl, 0)
end

function gpio_init()
	gpio.mode(1, gpio.INPUT)
end

function gpio_sense_h4n()
	if (gpio.read(1) == 1) then
		print("H4N connected")
		serial_init()
		connect_d()
		connect()
	else
		print("H4N not connected")
		tmr.start(1)
	end
end

function gpio_sense_h4n_d()
	tmr.register(1, 1000, tmr.ALARM_SEMI, gpio_sense_h4n)
end

function serial_settag_down()
	uart.write(0, 0x81)
	uart.write(0, 0x00)
	tmr.start(2)
end

function serial_settag_up()
	uart.write(0, 0x80)
	uart.write(0, 0x00)
end

function serial_settag_d()
	tmr.register(2, 200, tmr.ALARM_SEMI, serial_settag_up)
end

function dostuff(conn,payload)
	if (connected == 0) then
		conn:send("not connected")
	else
		conn:send("Marker gesetzt(?)")
		serial_settag_down()
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

serial_settag_d()
gpio_init()
gpio_sense_h4n_d()
gpio_sense_h4n()
