module main

fn test_format_status_full() {
	s := Status{
		model_display: 'Sonnet'
		dir_name: 'vai'
		branch: 'feature-xyz'
		cost_usd: 0.01234
		used_pct: 8.0
		has_pct: true
		has_cache_hit: true
		cache_hit: 0.91
		rate_5h: RateWindow{
			used_pct: 23.5
			present: true
		}
		has_pr: true
		pr_number: 1234
		pr_state: 'pending'
	}
	out := format_status(s)
	assert out.contains('Sonnet')
	assert out.contains('vai')
	assert out.contains('(feature-xyz)')
	assert out.contains('PR#1234')
	assert out.contains('8%')
	assert out.contains('\$0.0123')
	assert out.contains('cache 91%')
	assert out.contains('5h 24%')
	assert out.split('\n').len == 2
}

fn test_format_status_minimal_has_no_optional_segments() {
	s := Status{
		model_display: 'Sonnet'
		cost_usd: 0.0
	}
	out := format_status(s)
	assert out.contains('Sonnet')
	assert !out.contains('PR#')
	assert !out.contains('cache')
	assert !out.contains('5h')
	assert out.contains('ctx: n/a')
}

fn test_progress_bar_bounds() {
	assert progress_bar(0.0, 10) == '----------'
	assert progress_bar(100.0, 10) == '##########'
	assert progress_bar(150.0, 10) == '##########'
	assert progress_bar(-5.0, 10) == '----------'
}

fn test_bar_color_thresholds() {
	assert bar_color(10.0) == green
	assert bar_color(60.0) == yellow
	assert bar_color(90.0) == red
}
