module probe

import config
import modbus
import log
import time
import sync

struct MODBUS {
mut:
	m     &modbus.Modbus_t
	mutex &sync.Mutex
}

pub fn new_modbus(c &config.CONFIG) &MODBUS {
	cc := c.modbus
	log.info('setup modbus. ${c}')
	device := cc.device
	baud := cc.baud
	parity := cc.parity[0]
	data_bit := cc.data_bit
	stop_bit := cc.stop_bit

	mut tmp := MODBUS{
		m:     modbus.modbus_new_rtu(device, baud, parity, data_bit, stop_bit) or { panic(err) }
		mutex: c.mutex
	}
	modbus.modbus_set_byte_timeout(mut tmp.m, 0, cc.byte_timeout * 1000)
	modbus.modbus_set_response_timeout(mut tmp.m, 0, cc.res_timeout * 1000)
	modbus.modbus_set_debug(mut tmp.m, 0)

	for i := 0; i < 100; i++ {
		modbus.modbus_connect(mut tmp.m) or {
			log.info('${err}')
			if i > 10 {
				log.info('too many retry connecting serial dev, iam give up.')
				exit(-1)
			}
			time.sleep(1000 * time.millisecond)
		}
	}
	return &tmp
}

pub fn (mut m MODBUS) read_probe(mut p config.PROBE) {
	log.info('reading value probe: ${p.name}, reg: ${p.value_reg}')
	modbus.modbus_set_slave(mut m.m, p.addr) or { panic(err) }

	mut value := []u16{len: 2, init: 0}
	mut count := 0
	for i := 0; count != value.len && i < p.retry; i++ {
		m.mutex.@lock()
		count = modbus.modbus_read_registers(mut m.m, p.value_reg, value.len, mut value) or {
			m.mutex.unlock()
			time.sleep(time.millisecond * 250)
			log.info('${err} ${p.name} for value')
			if i == p.retry - 1 {
				log.info('error probe ${p.name} too many retry skip it')
				break
			}
			continue
		}
		p.value = modbus.modbus_get_float_abcd(value) or { panic(err) }
		m.mutex.unlock()
		break
	}

	if p.temp_reg == 0 {
		return
	}

	log.info('reading temp form probe ${p.name}, reg: ${p.temp_reg}')
	mut temp := []u16{len: 2, init: 0}
	count = 0
	for i := 0; count != temp.len && i < p.retry; i++ {
		m.mutex.@lock()
		count = modbus.modbus_read_registers(mut m.m, p.temp_reg, temp.len, mut temp) or {
			m.mutex.unlock()
			time.sleep(time.millisecond * 250)
			log.info('${err} ${p.name} for temp')
			if i == p.retry - 1 {
				log.info('error probe ${p.name} too many retry skip it')
				break
			}
			continue
		}
		p.temp = modbus.modbus_get_float_abcd(temp) or { panic(err) }
		m.mutex.unlock()
		break
	}
}
