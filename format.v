module main

import strings

const reset = '\x1b[0m'
const bold = '\x1b[1m'
const dim = '\x1b[2m'
const green = '\x1b[32m'
const yellow = '\x1b[33m'
const red = '\x1b[31m'

// bar_color flags context usage the same way most terminal UIs do:
// comfortable, getting close, act now.
fn bar_color(pct f64) string {
	if pct >= 80.0 {
		return red
	}
	if pct >= 50.0 {
		return yellow
	}
	return green
}

fn progress_bar(pct f64, width int) string {
	mut filled := int(f64(width) * pct / 100.0)
	if filled > width {
		filled = width
	}
	if filled < 0 {
		filled = 0
	}
	mut sb := strings.new_builder(width)
	for i in 0 .. width {
		sb.write_string(if i < filled { '#' } else { '-' })
	}
	return sb.str()
}

// format_status renders two lines: identity (model, directory, branch,
// open PR) and usage (context bar, cost, cache hit rate, 5-hour rate
// limit). Every segment after the model name is conditional on the
// matching field being present in the input.
pub fn format_status(s Status) string {
	mut line1 := strings.new_builder(96)
	line1.write_string('${bold}${s.model_display}${reset}')
	if s.dir_name != '' {
		line1.write_string(' ${dim}${s.dir_name}${reset}')
	}
	if s.branch != '' {
		line1.write_string(' (${s.branch})')
	} else if s.repo_name != '' {
		line1.write_string(' [${s.repo_name}]')
	}
	if s.has_pr {
		line1.write_string(' PR#${s.pr_number}')
		if s.pr_state != '' {
			line1.write_string(' ${s.pr_state}')
		}
	}

	mut line2 := strings.new_builder(96)
	if s.has_pct {
		color := bar_color(s.used_pct)
		bar := progress_bar(s.used_pct, 12)
		line2.write_string('${color}[${bar}] ${s.used_pct:.0f}%${reset} ctx')
	} else {
		line2.write_string('${dim}ctx: n/a${reset}')
	}
	line2.write_string('  \$${s.cost_usd:.4f}')
	if s.has_cache_hit {
		line2.write_string('  cache ${s.cache_hit * 100:.0f}%')
	}
	if s.rate_5h.present {
		line2.write_string('  5h ${s.rate_5h.used_pct:.0f}%')
	}

	return '${line1.str()}\n${line2.str()}'
}
