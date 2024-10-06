module config

import json
import log
import os
import sync

pub struct SERVER {
pub:
	port int
}

pub struct DB {
pub:
	host       string
	user       string
	password   string
	db_name    string
	loop_timer i64
}

pub struct MODBUS {
pub:
	device       string
	baud         int
	parity       string
	data_bit     int
	stop_bit     int
	byte_timeout u32
	res_timeout  u32
	loop_timer   i64
}

pub struct PROBE {
pub:
	name       string
	addr       int
	value_reg  int
	temp_reg   int
	retry      int
	kabp_reg   int
	value_min  f32
	value_max  f32
	value_rand f32
pub mut:
	ka         f32
	kb         f32
	enable     bool
	error      int @[json: '-']
	value_raw  f32 @[json: '-']
	value_calc f32 @[json: '-']
	temp       f32 @[json: '-']
	flow       f32 @[json: '-']
	total      u32 @[json: '-']
	kap        f32 @[json: '-']
	kbp        f32 @[json: '-']
}

@[heap]
pub struct CONFIG {
mut:
	path string @[json: '-']
pub mut:
	modbus MODBUS
	ph     PROBE
	cod    PROBE
	tss    PROBE
	nh3n   PROBE
	db     DB
	server SERVER
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

pub fn (mut c CONFIG) save() {
	json_str := json.encode_pretty(c)
	os.write_file(c.path, json_str) or { panic(err) }
}
