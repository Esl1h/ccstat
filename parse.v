module main

import json2

// parse_status reads Claude Code's statusline JSON contract
// (https://code.claude.com/docs/en/statusline.md). Every field it reads
// is optional in practice: `context_window.current_usage` is null before
// the first API response, `rate_limits` only appears for Pro/Max
// subscribers, `prompt_cache` needs Claude Code v2.1.251+, `pr` only
// exists with an open PR. A missing or null field is left at its zero
// value, never an error.
pub fn parse_status(raw string) !Status {
	val := json2.decode[json2.Any](raw) or { return error(one_line_error(err.msg())) }
	if val !is map[string]json2.Any {
		return error('expected a JSON object')
	}
	obj := val.as_map()
	mut s := Status{}

	if model_val := obj['model'] {
		m := model_val.as_map()
		if v := m['display_name'] {
			s.model_display = v.str()
		}
	}

	if ws_val := obj['workspace'] {
		w := ws_val.as_map()
		if v := w['current_dir'] {
			s.dir_name = last_path_segment(v.str())
		}
		if v := w['git_worktree'] {
			s.worktree = v.str()
		}
		if repo_val := w['repo'] {
			r := repo_val.as_map()
			if v := r['name'] {
				s.repo_name = v.str()
			}
		}
	}

	if cost_val := obj['cost'] {
		c := cost_val.as_map()
		if v := c['total_cost_usd'] {
			s.cost_usd = v.f64()
		}
	}

	if cw_val := obj['context_window'] {
		cw := cw_val.as_map()
		if v := cw['used_percentage'] {
			if v !is json2.Null {
				s.used_pct = v.f64()
				s.has_pct = true
			}
		}
		if cu_val := cw['current_usage'] {
			if cu_val !is json2.Null {
				cu := cu_val.as_map()
				if v := cu['input_tokens'] {
					s.input_tokens = int(v.f64())
				}
				if v := cu['output_tokens'] {
					s.output_tokens = int(v.f64())
				}
				if v := cu['cache_creation_input_tokens'] {
					s.cache_write = int(v.f64())
				}
				if v := cu['cache_read_input_tokens'] {
					s.cache_read = int(v.f64())
				}
				s.has_usage = true
			}
		}
	}

	if rl_val := obj['rate_limits'] {
		rl := rl_val.as_map()
		if fh_val := rl['five_hour'] {
			fh := fh_val.as_map()
			if v := fh['used_percentage'] {
				s.rate_5h = RateWindow{
					used_pct: v.f64()
					present:  true
				}
			}
		}
	}

	if pc_val := obj['prompt_cache'] {
		pc := pc_val.as_map()
		if v := pc['hit_ratio'] {
			if v !is json2.Null {
				s.cache_hit = v.f64()
				s.has_cache_hit = true
			}
		}
	}

	if pr_val := obj['pr'] {
		pr := pr_val.as_map()
		if v := pr['number'] {
			s.pr_number = int(v.f64())
			s.has_pr = true
		}
		if v := pr['review_state'] {
			s.pr_state = v.str()
		}
	}

	return s
}

// one_line_error flattens json2's decode error, which carries a multi-line
// context decorated with ANSI color codes even when not writing to a tty,
// into the single plain line a statusline can show.
fn one_line_error(msg string) string {
	mut out := []u8{}
	b := msg.bytes()
	mut i := 0
	for i < b.len {
		if b[i] == 27 && i + 1 < b.len && b[i + 1] == `[` {
			i += 2
			for i < b.len && !(b[i] >= 0x40 && b[i] <= 0x7e) {
				i++
			}
			i++
			continue
		}
		out << b[i]
		i++
	}
	lines := out.bytestr().split_into_lines().filter(it.trim_space() != '')
	if lines.len == 0 {
		return 'invalid json'
	}
	return lines[0].trim_space()
}

fn last_path_segment(path string) string {
	idx := path.last_index('/') or { return path }
	return path[idx + 1..]
}
