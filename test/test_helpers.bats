#!/usr/bin/env bats
# test_helpers.bats — info, warn, error, prompt_choice

load test_helper

@test "info: outputs to stdout with INFO prefix" {
	run info "test message"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == "INFO: test message" ]]
}

@test "warn: outputs to stderr with WARNING prefix" {
	run warn "test warning"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == "WARNING: test warning" ]]
}

@test "error: outputs to stderr with ERROR prefix" {
	run error "test error"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == "ERROR: test error" ]]
}

@test "prompt_choice: returns valid choice on first try" {
	run bash -c 'source "'"${SCRIPT_DIR}"'/dockcode"; prompt_choice "Pick one" "" "opt1" "opt2" <<< "1"'
	[[ "${status}" -eq 0 ]]
	# The choice "1" is echoed to stdout; stderr has the prompt text
	[[ "${output}" == *"1"* ]]
}

@test "prompt_choice: re-prompts on invalid input then accepts valid" {
	run bash -c 'source "'"${SCRIPT_DIR}"'/dockcode"; prompt_choice "Pick one" "" "opt1" "opt2" <<< $'"'"'invalid\n2'"'"''
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Invalid choice"* ]]
	[[ "${output}" == *"2"* ]]
}

@test "prompt_choice: re-prompts on out of range input" {
	run bash -c 'source "'"${SCRIPT_DIR}"'/dockcode"; prompt_choice "Pick one" "" "opt1" "opt2" <<< $'"'"'5\n1'"'"''
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Invalid choice"* ]]
	[[ "${output}" == *"1"* ]]
}

@test "prompt_choice: shows numbered options" {
	run bash -c 'source "'"${SCRIPT_DIR}"'/dockcode"; prompt_choice "Pick one" "" "alpha" "beta" <<< "1"'
	[[ "${output}" == *"1) alpha"* ]]
	[[ "${output}" == *"2) beta"* ]]
}
