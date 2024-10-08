module server

import veb
import config
import time

// Our context struct must embed `veb.Context`!
struct Context {
	veb.Context
}

pub struct Server {
	veb.StaticHandler
pub mut:
	conf &config.CONFIG
}

pub fn new_server(mut c config.CONFIG) &Server {
	return &Server{
		conf: &c
	}
}

pub fn (mut s Server) hello(mut ctx Context) veb.Result {
	ctx.set_content_type('application/json')
	return ctx.text('{"hello":"world"}')
}

pub fn (mut s Server) index(mut ctx Context) veb.Result {
	page_title := 'Menu'
	return $veb.html('index.html')
}

pub fn (mut s Server) read(mut ctx Context) veb.Result {
	s.conf.mutex.@lock()
	p := &s.conf
	ph := p.ph.value_calc
	cod := p.cod.value_calc
	tss := p.tss.value_calc
	nh3n := p.nh3n.value_calc
	temp := p.ph.temp
	s.conf.mutex.unlock()
	page_title := 'Hasil Pembacaan Probe'
	return $veb.html('read.html')
}

@['/read_all'; get]
pub fn (mut s Server) probe_read_all(mut ctx Context) veb.Result {
	ctx.set_content_type('application/json')
	timestamp := time.now().unix()
	p := &s.conf
	data := '{"TIME":${timestamp}, "TEMPERATURE":${p.ph.temp},' +
		'"PH_raw": ${p.ph.value_raw},"PH_calc": ${p.ph.value_calc},' +
		'"COD_raw":${p.cod.value_raw}, "COD_calc": ${p.cod.value_calc},' +
		'"TSS_raw":${p.cod.value_raw}, "TSS_calc":${p.tss.value_calc},' +
		'"NH3N_raw":${p.cod.value_raw},"NH3N_calc":${p.cod.value_calc},' + '"FLOW":0,"TOTAL":0}'
	return ctx.text(data)
}

@['/probe_set']
pub fn (mut s Server) probe_set(mut ctx Context) veb.Result {
	s.conf.mutex.@lock()
	defer {
		s.conf.mutex.unlock()
	}

	mut lp := [&s.conf.ph, &s.conf.cod, &s.conf.tss, &s.conf.nh3n]
	mut status := []string{}
	for mut e in lp {
		tmp := ctx.query[e.name]
		if tmp.len == 0 {
			continue
		} else if tmp == 'true' {
			e.enable = true
		} else if tmp == 'false' {
			e.enable = false
		}
		status << '${e.name} is ${tmp}'
	}
	if status.len == 0 {
		status << 'tidak ada request atau salah paling?'
	}
	return ctx.text('${status}')
}

@['/config'; get]
pub fn (mut s Server) config(mut ctx Context) veb.Result {
	return ctx.json(s.conf)
}

@['/config_save'; get]
pub fn (mut s Server) config_save(mut ctx Context) veb.Result {
	s.conf.save()
	return ctx.json(s.conf)
}

fn offset_all(mut s Server, mut ctx Context, mut p config.PROBE) veb.Result {
	ka_new_str := ctx.query['KA']
	kb_new_str := ctx.query['KB']

	page_title := 'setting ${p.name} offset'
	probe_name := p.name

	mut ka := p.ka
	mut kb := p.kb

	s.conf.mutex.@lock()
	if ka_new_str.len > 0 {
		ka = ka_new_str.f32()
		p.ka = ka
	}

	if kb_new_str.len > 0 {
		kb = kb_new_str.f32()
		p.kb = kb
	}
	s.conf.mutex.unlock()
	return $veb.html('offset.html')
}

@['/ph/offset']
pub fn (mut s Server) ph_offset(mut ctx Context) veb.Result {
	return offset_all(mut s, mut ctx, mut s.conf.ph)
}

@['/cod/offset']
pub fn (mut s Server) cod_offset(mut ctx Context) veb.Result {
	return offset_all(mut s, mut ctx, mut s.conf.cod)
}

@['/tss/offset']
pub fn (mut s Server) tss_offset(mut ctx Context) veb.Result {
	return offset_all(mut s, mut ctx, mut s.conf.tss)
}

@['/nh3n/offset']
pub fn (mut s Server) nh3n_offset(mut ctx Context) veb.Result {
	return offset_all(mut s, mut ctx, mut s.conf.nh3n)
}

pub fn (mut s Server) run() {
	s.handle_static('static', true) or { panic(err) }
	spawn fn [mut s] () {
		for {
			veb.run[Server, Context](mut s, s.conf.server.port)
		}
	}()
}
