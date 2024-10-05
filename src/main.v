module main

import log
import modbus

fn main() {
	mut m := modbus.modbus_new_rtu('/dev/tnt1', 9600, `N`, 8, 1) or { panic(err) }
	modbus.modbus_set_slave(mut m, 1) or { panic(err) }
	modbus.modbus_set_byte_timeout(mut m, 0, 100_000)
	modbus.modbus_set_response_timeout(mut m, 1, 0)
	modbus.modbus_set_debug(mut m, 1)
	modbus.modbus_connect(mut m) or { panic(err) }

	mut data := []u16{len: 2, init: 0}
	modbus.modbus_read_registers(mut m, 0, 2, mut data) or { panic(err) }

	log.info('data: ${data}')
}
