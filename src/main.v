module main

import log
import config
import probe

fn main() {
	mut c := config.new_config('config.json')
	mut p := probe.new_modbus(c)
	p.read_probe(mut c.ph)

	log.info('c.ph.value: ${c.ph.value}')
	log.info('c.ph.temp: ${c.ph.temp}')
}
