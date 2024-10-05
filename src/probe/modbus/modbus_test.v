module modbus

import log

fn test_create_modbus() {
	mut l := log.Log{}
	mut t := modbus_new_rtu('/dev/tnt1', 9600, `N`, 8, 1) or { panic(err) }

	modbus_set_debug(mut t, 1)

	modbus_set_slave(mut t, 1) or { panic(err) }

	modbus_connect(mut t) or { panic(err) }

	mut data := []u16{len: 10, init: 0}

	e := modbus_read_registers(mut t, 0, 1, mut data) or { panic(err) }
	assert e == 1
	assert data[0] == 123

	modbus_close(mut t)
	modbus_free(mut t)
}

fn test_floating() {
	mut d := []u16{len: 2, init: 0}
	modbus_set_float_abcd(0.123, mut d) or { panic(err) }
	assert d[0] == 0xfb3d && d[1] == 0x6de7

	e := modbus_get_float_badc(d) or { panic(err) }
	assert e == 0.123
}
