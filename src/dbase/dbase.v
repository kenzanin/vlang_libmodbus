module dbase

import db.pg
import config
import time
import log
import sync

pub struct DBASE {
mut:
	ph_val     &f32
	cod_val    &f32
	tss_val    &f32
	nh3n_val   &f32
	loop_timer &i64
	db         &pg.DB
	mutex      &sync.Mutex
}

pub fn new_db(mut c config.CONFIG) &DBASE {
	c_db := c.db
	db_config := pg.Config{
		host:     c_db.host
		user:     c_db.user
		password: c_db.password
		dbname:   c_db.db_name
	}
	mut db := pg.connect(db_config) or { panic(err) }
	return &DBASE{
		db:         &db
		ph_val:     &c.ph.value_calc
		cod_val:    &c.cod.value_calc
		tss_val:    &c.tss.value_calc
		nh3n_val:   &c.nh3n.value_calc
		loop_timer: &c.db.loop_timer
		mutex:      c.mutex
	}
}

pub fn (mut d DBASE) insert() {
	d.mutex.@lock()
	defer {
		d.mutex.unlock()
	}
	ph := *d.ph_val
	cod := *d.cod_val
	tss := *d.tss_val
	nh3n := *d.nh3n_val
	timestamp := time.now().unix().str()

	log.info('insert into db, time: ${timestamp},ph: ${ph},' +
		' cod: ${cod}, tss: ${tss}, nh3n: ${nh3n}')
	d.db.exec_param_many('
	insert into sparing (time, ph, cod, tss, nh3n)
	values ($1, $2, $3, $4, $5)',
		[timestamp, ph.str(), cod.str(), tss.str(), nh3n.str()]) or { panic(err) }
}

pub fn (mut d DBASE) run() {
	spawn fn [mut d] () {
		for {
			time.sleep((*d.loop_timer) * time.millisecond)
			d.insert()
		}
	}()
}

pub fn (mut d DBASE) close() {
	d.db.close()
}
