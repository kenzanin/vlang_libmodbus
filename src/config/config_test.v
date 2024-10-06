module config

fn test_load() {
	mut c := new_config('test_read.json')
}

fn test_save() {
	mut a := new_config('config.json')
	a.save()
	mut b := new_config('config.json')
	assert a == b
}
