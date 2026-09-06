module main

import os

fn main() {
	raw := os.get_raw_lines_joined()
	status := parse_status(raw) or {
		println('ccstat: ${err}')
		return
	}
	println(format_status(status))
}
