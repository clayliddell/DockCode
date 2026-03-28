#!/usr/bin/env bats
# test_launch.bats — handle_launch, interactive_launch

load test_helper

@test "handle_launch: errors on unknown flag" {
	run handle_launch --unknown
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Unknown flag"* ]]
}

@test "handle_launch: errors when -n has no value" {
	run handle_launch -n
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"requires a value"* ]]
}

@test "handle_launch: errors when -w has no value" {
	run handle_launch -w
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"requires a value"* ]]
}

@test "handle_launch: errors on invalid workspace" {
	run handle_launch -n test -w /nonexistent/directory
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"does not exist"* ]]
}

@test "handle_launch: launches existing sandbox when found" {
	set_mock_response "sandbox_ls" '{"vms":[{"name":"my-sandbox"}]}'
	set_mock_response "sandbox_run" ""

	run handle_launch -n "my-sandbox"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox run my-sandbox"
	[[ "${output}" == *"Launching existing sandbox"* ]]
}

@test "handle_launch: creates new sandbox when not found" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	set_mock_response "sandbox_run" ""

	local workspace="${TEST_TMPDIR}/workspace"
	mkdir -p "${workspace}"
	# Pre-create config files to avoid resolve_config prompts
	echo '{}' >"${OPENCODE_CONFIG}"
	echo '{}' >"${AUTH_CONFIG}"

	# "x" for press-any-key after create_sandbox
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export OPENCODE_CONFIG="'"${OPENCODE_CONFIG}"'"
		export AUTH_CONFIG="'"${AUTH_CONFIG}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		printf "x" | handle_launch -n new-sandbox -w "'"${workspace}"'"
	'
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox create"
	assert_docker_called_with "sandbox run"
}

@test "handle_launch: defaults name from workspace basename" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	set_mock_response "sandbox_run" ""

	local workspace="${TEST_TMPDIR}/myproject"
	mkdir -p "${workspace}"
	echo '{}' >"${OPENCODE_CONFIG}"
	echo '{}' >"${AUTH_CONFIG}"

	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export OPENCODE_CONFIG="'"${OPENCODE_CONFIG}"'"
		export AUTH_CONFIG="'"${AUTH_CONFIG}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		printf "x" | handle_launch -w "'"${workspace}"'"
	'
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "myproject"
}

@test "interactive_launch: create new sandbox flow" {
	set_mock_response "sandbox_ls" '{"vms":[{"name":"existing-sb"}]}'
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	set_mock_response "sandbox_run" ""

	local workspace="${TEST_TMPDIR}/newproject"
	mkdir -p "${workspace}"
	echo '{}' >"${OPENCODE_CONFIG}"
	echo '{}' >"${AUTH_CONFIG}"

	# Choice 1 = "Create a new sandbox"
	# Then default workspace (empty = use PWD), then default name (empty)
	# "x" for press-any-key after create_sandbox
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export OPENCODE_CONFIG="'"${OPENCODE_CONFIG}"'"
		export AUTH_CONFIG="'"${AUTH_CONFIG}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		cd "'"${workspace}"'"
		printf "1\n\n\nx" | interactive_launch
	'
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox create"
	assert_docker_called_with "sandbox run"
}

@test "interactive_launch: create new sandbox errors on nonexistent workspace" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	echo '{}' >"${OPENCODE_CONFIG}"
	echo '{}' >"${AUTH_CONFIG}"

	# Choice 1 = "Create a new sandbox" (no existing sandboxes)
	# Then provide a nonexistent workspace path
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export OPENCODE_CONFIG="'"${OPENCODE_CONFIG}"'"
		export AUTH_CONFIG="'"${AUTH_CONFIG}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		printf "1\n/nonexistent/workspace\n" | interactive_launch
	'
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"does not exist"* ]]
}

@test "interactive_launch: create new sandbox uses default name from workspace" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	set_mock_response "sandbox_run" ""

	local workspace="${TEST_TMPDIR}/my-project"
	mkdir -p "${workspace}"
	echo '{}' >"${OPENCODE_CONFIG}"
	echo '{}' >"${AUTH_CONFIG}"

	# Choice 1 = "Create a new sandbox" (no existing sandboxes)
	# Default workspace (empty), default name (empty → uses basename)
	# "x" for press-any-key after create_sandbox
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export OPENCODE_CONFIG="'"${OPENCODE_CONFIG}"'"
		export AUTH_CONFIG="'"${AUTH_CONFIG}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		cd "'"${workspace}"'"
		printf "1\n\n\nx" | interactive_launch
	'
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "my-project"
}

@test "handle_launch: no flags triggers interactive mode" {
	set_mock_response "sandbox_ls" '{"vms":[{"name":"existing-sb"}]}'
	set_mock_response "sandbox_run" ""

	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		printf "2" | handle_launch
	'
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox run existing-sb"
}
