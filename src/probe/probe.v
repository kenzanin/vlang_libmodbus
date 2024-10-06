module probe

import config
import modbus
import log
import time
import math
import rand

const retry_delay_ms = 250

pub struct MODBUS {
mut:
	conf &config.CONFIG
	m    &modbus.Modbus_t
}

pub fn new_modbus(mut c config.CONFIG) &MODBUS {
	cm := &c.modbus
	log.info('setup modbus. ${cm}')
	device := cm.device
	baud := cm.baud
	parity := cm.parity[0]
	data_bit := cm.data_bit
	stop_bit := cm.stop_bit

	mut tmp := &MODBUS{
		conf: &c
		m:    modbus.modbus_new_rtu(device, baud, parity, data_bit, stop_bit) or { panic(err) }
	}
	modbus.modbus_set_byte_timeout(mut tmp.m, 0, cm.byte_timeout * 1000)
	modbus.modbus_set_response_timeout(mut tmp.m, 0, cm.res_timeout * 1000)
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
	return tmp
}

pub fn (mut m MODBUS) modbus_close() {
	modbus.modbus_close(mut m.m)
	modbus.modbus_free(mut m.m)
}

pub fn (mut m MODBUS) read_value(mut p config.PROBE) {
	if !p.enable {
		log.info('reading ${p.name} disabled retain old value')
		return
	}

	log.info('reading value: ${p.name}, addr: ${p.addr}, reg: ${p.value_reg}')
	modbus.modbus_set_slave(mut m.m, p.addr) or { panic(err) }

	mut value := []u16{len: 2, init: 0}
	for i := 0; true; i++ {
		m.conf.mutex.@lock()
		modbus.modbus_read_registers(mut m.m, p.value_reg, value.len, mut value) or {
			m.conf.mutex.unlock()
			time.sleep(time.millisecond * retry_delay_ms)
			log.info('${err} ${p.name} for value')
			if i >= p.retry {
				log.info('error probe ${p.name} too many retry skip it')
				p.error = 1
				break
			}
			continue
		}
		mut tmp_val := modbus.modbus_get_float_abcd(value) or { panic(err) }
		tmp_val *= 100
		tmp_val = f32(math.round(tmp_val) / 100.0)

		p.value_raw = tmp_val

		tmp_val = (tmp_val * p.ka) + p.kb

		if tmp_val < p.value_min {
			tmp_val = p.value_min + (rand.f32() * p.value_rand)
		} else if tmp_val > p.value_max {
			tmp_val = p.value_max - (rand.f32() * p.value_rand)
		}

		p.value_calc = tmp_val

		log.info('value ${p.name}: ${p.value_raw}')
		m.conf.mutex.unlock()
		p.error = 0
		break
	}

	if p.temp_reg == 0 {
		return
	}

	log.info('reading temp ${p.name}, addr: ${p.addr}, reg: ${p.temp_reg}')
	mut temp := []u16{len: 2, init: 0}
	for i := 0; true; i++ {
		m.conf.mutex.@lock()
		modbus.modbus_read_registers(mut m.m, p.temp_reg, temp.len, mut temp) or {
			m.conf.mutex.unlock()
			time.sleep(time.millisecond * retry_delay_ms)
			log.info('${err} ${p.name} for temp')
			if i == p.retry {
				log.info('error probe ${p.name} too many retry skip it')
				break
			}
			continue
		}
		mut temp_val := modbus.modbus_get_float_abcd(temp) or { panic(err) }
		temp_val *= 100
		temp_val = f32(math.round(temp_val) / 100.0)

		p.temp = temp_val

		log.info('temp ${p.name}: ${p.temp}')
		m.conf.mutex.unlock()
		break
	}
}

// pub fn modbus_write_and_read_registers(mut m Modbus_t,
//	write_addr int, write_nb int, s []u16,
//	read_addr int, read_nb int, mut dest []u16) !
pub fn (mut m MODBUS) write_offset(p &config.PROBE, ka f32, kb f32) {
	mut data_w := []u16{len: 4, init: 0}
	mut data_r := []u16{len: 4, init: 0}
	modbus.modbus_set_float_abcd(ka, mut data_w) or { panic(err) }
	modbus.modbus_set_float_abcd(kb, mut data_w[2..]) or { panic(err) }

	for i := 0; data_r != data_w; i++ {
		m.conf.mutex.@lock()
		modbus.modbus_write_and_read_registers(mut m.m, p.kabp_reg, data_w.len, data_w,
			p.kabp_reg, data_r.len, mut data_r) or { log.info('${err}') }
		m.conf.mutex.unlock()
		if data_w == data_r {
			break
		}
		if i == p.retry {
			log.info('writing offset ${p.name} too many retry skip it')
			break
		}
		log.info('writing offset ${p.name} error')
		time.sleep(retry_delay_ms * time.millisecond)
	}
}

pub fn (mut m MODBUS) read_offset(mut p config.PROBE) (f32, f32) {
	mut data := []u16{len: 4, init: 0}
	mut ka := f32(0)
	mut kb := f32(0)
	for i := 0; true; i++ {
		m.conf.mutex.@lock()
		modbus.modbus_read_registers(mut m.m, p.kabp_reg, data.len, mut data) or {
			m.conf.mutex.unlock()
			time.sleep(retry_delay_ms * time.millisecond)
			log.info('${err}')
			continue
		}
		m.conf.mutex.unlock()
		ka = modbus.modbus_get_float_abcd(data[0..2]) or { panic(err) }
		kb = modbus.modbus_get_float_abcd(data[2..4]) or { panic(err) }
		log.info('offset ${p.name} kap: ${ka}, kbp: ${kb}')
		break
	}
	return ka, kb
}

pub fn (mut p MODBUS) run() {
	spawn fn [mut p] () {
		mut lp := [&p.conf.ph, &p.conf.cod, &p.conf.tss, &p.conf.nh3n]
		for {
			for mut e in lp {
				p.read_value(mut *e)
				time.sleep(p.conf.modbus.loop_timer * time.millisecond)
			}
		}
	}()
}
