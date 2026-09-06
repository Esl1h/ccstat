// ccstat is a Claude Code statusline command: it reads the session JSON
// Claude Code writes to stdin and prints a compact status line. Its whole
// pitch is startup speed: a statusline command runs on every turn, and a
// Python or Node one costs 80-300ms just to boot the interpreter. This is
// a static V binary, no runtime, sub-5ms cold start.
module main

// RateWindow is one of rate_limits.{five_hour,seven_day,spend_limit}.
// Absent means the field wasn't in the JSON at all, distinct from 0%.
struct RateWindow {
mut:
	used_pct f64
	present  bool
}

// Status is everything ccstat prints, parsed defensively out of Claude
// Code's statusline JSON: most fields are optional or version-gated, and
// a field ccstat doesn't recognize should never break the whole line.
struct Status {
mut:
	model_display string
	dir_name      string
	branch        string
	repo_name     string
	cost_usd      f64
	used_pct      f64
	has_pct       bool
	input_tokens  int
	output_tokens int
	cache_write   int
	cache_read    int
	has_usage     bool
	rate_5h       RateWindow
	cache_hit     f64
	has_cache_hit bool
	pr_number     int
	pr_state      string
	has_pr        bool
}
