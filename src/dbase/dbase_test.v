module dbase

import config

fn test_new_db() {
	mut c := config.new_config('config.json')
	mut d := new_db(mut c)
	defer {
		d.db.close()
	}
}

fn test_insert() {
	mut c := config.new_config('config.json')
	mut d := new_db(mut c)
	defer {
		d.db.close()
	}
	c.ph.value = 100.0
	c.cod.value = 101.0
	c.tss.value = 102.0
	c.nh3n.value = 103.0

	d.insert()
}
