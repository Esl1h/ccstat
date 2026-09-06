module main

const full_fixture = '{
  "cwd": "/home/esli/GIT/vai",
  "session_id": "abc123",
  "transcript_path": "/home/esli/.claude/projects/x/abc123.jsonl",
  "model": {"id": "claude-sonnet-5", "display_name": "Sonnet"},
  "workspace": {
    "current_dir": "/home/esli/GIT/vai",
    "project_dir": "/home/esli/GIT/vai",
    "added_dirs": [],
    "git_worktree": "feature-xyz",
    "repo": {"host": "github.com", "owner": "Esl1h", "name": "vai"}
  },
  "version": "2.1.90",
  "output_style": {"name": "default"},
  "cost": {
    "total_cost_usd": 0.01234,
    "total_duration_ms": 45000,
    "total_api_duration_ms": 2300,
    "total_lines_added": 156,
    "total_lines_removed": 23
  },
  "context_window": {
    "total_input_tokens": 15500,
    "total_output_tokens": 1200,
    "context_window_size": 200000,
    "used_percentage": 8,
    "remaining_percentage": 92,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  },
  "exceeds_200k_tokens": false,
  "prompt_cache": {"warm": true, "hit_ratio": 0.91},
  "rate_limits": {
    "five_hour": {"used_percentage": 23.5, "resets_at": 1738425600}
  },
  "pr": {"number": 1234, "url": "https://github.com/x/pull/1234", "review_state": "pending"}
}'

const minimal_fixture = '{
  "cwd": "/home/esli/GIT/vai",
  "session_id": "abc123",
  "transcript_path": "/tmp/x.jsonl",
  "model": {"id": "claude-sonnet-5", "display_name": "Sonnet"},
  "workspace": {"current_dir": "/home/esli/GIT/vai", "project_dir": "/home/esli/GIT/vai", "added_dirs": []},
  "version": "2.1.90",
  "output_style": {"name": "default"},
  "cost": {"total_cost_usd": 0.0, "total_duration_ms": 100, "total_api_duration_ms": 0, "total_lines_added": 0, "total_lines_removed": 0},
  "context_window": {
    "total_input_tokens": 0,
    "total_output_tokens": 0,
    "context_window_size": 200000,
    "used_percentage": null,
    "remaining_percentage": null,
    "current_usage": null
  },
  "exceeds_200k_tokens": false
}'

fn test_parse_full_fixture() {
	s := parse_status(full_fixture) or {
		assert false, err.msg()
		return
	}
	assert s.model_display == 'Sonnet'
	assert s.dir_name == 'vai'
	assert s.worktree == 'feature-xyz'
	assert s.repo_name == 'vai'
	assert s.cost_usd == 0.01234
	assert s.has_pct
	assert s.used_pct == 8.0
	assert s.has_usage
	assert s.input_tokens == 8500
	assert s.output_tokens == 1200
	assert s.cache_write == 5000
	assert s.cache_read == 2000
	assert s.has_cache_hit
	assert s.cache_hit == 0.91
	assert s.rate_5h.present
	assert s.rate_5h.used_pct == 23.5
	assert s.has_pr
	assert s.pr_number == 1234
	assert s.pr_state == 'pending'
}

fn test_parse_minimal_fixture_no_crash_on_absent_fields() {
	s := parse_status(minimal_fixture) or {
		assert false, err.msg()
		return
	}
	assert s.model_display == 'Sonnet'
	assert s.worktree == ''
	assert !s.has_pct
	assert !s.has_usage
	assert !s.has_cache_hit
	assert !s.rate_5h.present
	assert !s.has_pr
}

fn test_parse_rejects_non_object() {
	if _ := parse_status('[1,2,3]') {
		assert false, 'expected an error'
	}
}

fn test_last_path_segment() {
	assert last_path_segment('/home/esli/GIT/vai') == 'vai'
	assert last_path_segment('vai') == 'vai'
	assert last_path_segment('/') == ''
}

fn test_parse_status_error_is_one_plain_line() {
	// json2 decorates decode errors with ANSI codes and a multi-line
	// context; a statusline must get one plain line back.
	if _ := parse_status('garbage') {
		assert false, 'expected an error'
	} else {
		assert !err.msg().contains('\x1b'), err.msg()
		assert !err.msg().contains('\n'), err.msg()
		assert err.msg() != ''
	}
}
