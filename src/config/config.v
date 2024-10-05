module config

import json
import log
import os
import sync

pub struct MODBUS {
pub:
	device       string
	baud         int
	parity       string
	data_bit     int
	stop_bit     int
	byte_timeout u32
	res_timeout  u32
}

pub struct PROBE {
pub:
	name      string
	addr      int
	value_reg int
	temp_reg  int
	retry     int
pub mut:
	enable bool
	value  f32 @[json: '-']
	temp   f32 @[json: '-']
}

pub struct CONFIG {
mut:
	path string @[json: '-']
pub mut:
	modbus MODBUS
	ph     PROBE
	cod    PROBE
	tss    PROBE
	nh3n   PROBE
	mutex  &sync.Mutex @[json: '-']
}

pub fn new_config(file string) &CONFIG {
	log.info('oppening file: ${file}')
	file_content := os.read_file(file) or { panic(err) }
	mut config := json.decode(CONFIG, file_content) or { panic(err) }
	config.path = file
	config.mutex = sync.new_mutex()
	log.info('config json format:\n${config}')
	return &config
}

pub fn (c &CONFIG) save() {
	json_str := json.encode_pretty(c)
	os.write_file(c.path, json_str) or { panic(err) }
}
