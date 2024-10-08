module main

import config
import probe
import server
import dbase
import log
import os
import time

fn main() {
	mut file := ''
	if os.args.len == 1 {
		log.info('jangan lupa file config nya contoh ${os.args[0]} config.json, jika menggunakan file config lain.')
		log.info('load default config.json file')
		file = 'config.json'
	} else {
		file = os.args[1]
	}

	if !os.is_file(file) {
		log.info('error ${file} not exist')
		exit(-1)
	}
	
	mut c := config.new_config(file)
	mut m := probe.new_modbus(mut c)
	mut d := dbase.new_dbase(mut c)
	mut s := server.new_server(mut c)

	m.run()
	d.run()
	s.run()

	os.signal_opt(os.Signal.int, fn [mut m, mut d] (sig os.Signal) {
		println('Caught SIGINT (Ctrl+C), exiting...')
		m.modbus_close()
		d.close()
		log.info('cleaning up.')
		exit(0)
	}) or { panic(err) }
	for {
		time.sleep(1000 * time.millisecond)
	}
}
