module config

import json
import os

fn test_load() {
	mut c := new_config('test_read.json')
	assert c == CONFIG{
		path:   'test_read.json'
		modbus: MODBUS{
			device:   '/dev/tnt1'
			baud:     9600
			parity:   'N'
			data_bit: 8
			stop_bit: 1
		}
	}
}

fn test_save() {
	a := new_config('test_read.json')
	a.save()
	b := new_config('test_read.json')
	assert a == b
}
