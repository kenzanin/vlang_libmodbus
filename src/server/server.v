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
mut:
	conf &config.CONFIG
}

pub fn (mut s Server) hello(mut ctx Context) veb.Result {
	ctx.set_content_type('application/json')
	return ctx.text('{"hello":"world"}')
}

pub fn (mut s Server) index(mut ctx Context) veb.Result {
	return ctx.html('
<html>
<head>
    <title> Server Sparing </title>
</head>
<body>
    <h1>keluh kesah hub. kenzanin@gmail.com</h1>
	menu<br>
	1. <a href="/index">home</a><br>
	2. <a href="/read">read probe</a><br>
</body>
</html>')
}

pub fn (mut s Server) read(mut ctx Context) veb.Result {
	s.conf.mutex.@lock()
	defer {
		s.conf.mutex.unlock()
	}
	data := '
<html>
<head>
    <title> Server Sparing </title>
</head>
<body>
<h1>hasil pembacaan sensor</h1>
<br>
PH: ${s.conf.ph.value_calc}<br>
COD: ${s.conf.cod.value_calc}<br>
TSS: ${s.conf.tss.value_calc}<br>
NH3N: ${s.conf.nh3n.value_calc}<br>
flow: 0<br>
total: 0<br>
temp: ${s.conf.ph.temp}<br>
<br>
menu<br>
1. <a href="/index">home</a><br>
</body>
</html>'
	return ctx.html(data)
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
pub fn (mut s Server) ph_enable(mut ctx Context) veb.Result {
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

pub fn new_server(mut c config.CONFIG) &Server {
	return &Server{
		conf: &c
	}
}

pub fn (mut s Server) run() {
	s.handle_static('static', true) or { panic(err) }
	spawn fn [mut s] () {
		for {
			veb.run[Server, Context](mut s, s.conf.server.port)
		}
	}()
}
