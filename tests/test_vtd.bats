#!/usr/bin/env bats

load setup_bats
load setup_testname

teardown_vtd() {
    # VTD_LAUNCH is only available in the shell.
    cloe_shell -c '${VTD_LAUNCH} stop'
}

test_vtd_plugin_exists() {
    # VTD_ROOT is only available in the shell.
    cloe_shell -c 'test -d "${VTD_ROOT}"'
}

teardown() {
    # It's harmless to stop vtd multiple times, so do it in case something goes wrong.
    if test_vtd_plugin_exists; then
        echo "Teardown VTD (from BATS)"
        teardown_vtd
    fi
    # Remove the temporary registry.
    rm -r "$cloe_tmp_registry" || true
}

@test "$(testname "Expect check/run success" "test_vtd_smoketest.json" "515fa80c-fb35-48f3-840e-7825c6443c92")" {
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi
    cloe_engine check test_vtd_smoketest.json
    cloe_engine run test_vtd_smoketest.json
}

@test "$(testname "Expect check/run success" "test_vtd_api_recording.json" "71eaf779-2aa7-492b-83b5-27504ae92f9e")" {
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi
    cloe_engine check test_vtd_api_recording.json
    cloe_engine_with_tmp_registry run test_vtd_api_recording.json
    # Remove the test registry.
    rm -r "$cloe_tmp_registry" || true
}

@test "$(testname "Expect check/run success" "test_vtd_watchdog.json" "b3d51d61-2778-4fd4-b9ea-7711d1913395")" {
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi
    if ! type killall &>/dev/null; then
        skip "required program killall not present"
    fi

    cloe_engine check test_vtd_watchdog.json

    # assert abort with core dump, code 134/250
    run cloe_engine run test_vtd_watchdog.json
    test $status -eq $exit_outcome_syskill
}

@test "$(testname "Expect check/run success" "test_vtd_smoketest.json [ts=5ms]" "58f1411a-6f78-49af-832b-d7c884639ef7")" {
    BATS_OPTIONAL_STACKS="option_timestep_5.json"
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi
    cloe_engine check test_vtd_smoketest.json
    cloe_engine run test_vtd_smoketest.json
}

@test "$(testname "Expect check/run success" "test_vtd_smoketest.json [ts=60ms]" "4f9173c0-00df-49d9-b164-22f2996a5520")" {
    BATS_OPTIONAL_STACKS="option_timestep_60.json"
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi
    cloe_engine check test_vtd_smoketest.json
    cloe_engine run test_vtd_smoketest.json
}

@test "$(testname "Expect run success" "test_vtd_clean_timeout.json" "15439b9f-ac01-4e0b-b981-60064194880a")" {
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi

    run cloe_engine run test_vtd_clean_timeout.json
    assert_check_failure $status $output
    # This will look weird, that because of BATS.
    echo $output
    test $status -eq $exit_outcome_unknown
    echo $output | grep '### test successful ###'
}

# Note our open support request regarding stimulating multiple external
# vehicles in VTD: https://redmine.vires.com/issues/13340
#
# TODO: Improve the tested condition once we now how to correctly deal with VTD
@test "$(testname "Expect check/run success" "test_vtd_multi_agent_smoketest.json" "572ef7cf-67b2-47fd-849f-55339063208a")" {
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi
    cloe_engine check test_vtd_multi_agent_smoketest.json
    cloe_engine run test_vtd_multi_agent_smoketest.json
}

@test "$(testname "Expect run failure" "test_vtd_unknown_sensor.json" "ed9411da-d789-456d-9eb3-9cff63144775")" {
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi

    run cloe_engine run test_vtd_unknown_sensor.json
    test $status -eq $exit_outcome_unknown
}

@test "$(testname "Expect check/run success" "test_gndtruth_smoketest.json" "2554c4a8-297c-4d74-8944-44b67aa756a5")" {
    if ! test_plugin_exists gndtruth_extractor; then
        skip "required controller gndtruth_extractor not present"
    elif ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi

    local destfile="/tmp/cloe_gndtruth.json.gz"
    if [[ -f $destfile ]]; then
        rm $destfile
    fi
    cloe_engine check test_gndtruth_smoketest.json
    cloe_engine run test_gndtruth_smoketest.json
    test -s $destfile
    rm $destfile
}

# --------------------------------------------------------------------------- #
# The following tests require:
#
#   A VTD installation including the Module Manager Open Simulation Interface
#   (OSI) plugin.
#
# The plugin is available in the VTD wiki and is pre-installed in the Cloe VTD
# container.

test_vtd_osi_plugin_exists() {
    # VTD_ROOT is only available in the shell.
    cloe_shell -c 'test -f ${VTD_ROOT}/Data/Distros/Distro/Plugins/ModuleManager/libModuleOsi3Fmu.so'
}

test_vtd_osi_model_exists() {
    # VTD_ROOT is only available in the shell.
    cloe_shell -c 'test -n "$(echo "${VTD_EXTERNAL_MODELS}" | grep -o "OSMPDummySensor.so")"'
}

@test "$(testname "Expect check/run success" "test_vtd_smoketest_osi.json" "12b79a10-126c-4e21-8ebd-69f458651dd9")" {
    if ! test_vtd_plugin_exists; then
        skip "required simulator vtd not present"
    fi
    if ! test_vtd_osi_plugin_exists; then
        skip "required osi plugin for simulator vtd not present"
    fi
    if ! test_vtd_osi_model_exists; then
        skip "required osi sensor model for simulator vtd not present"
    fi
    cloe_engine check test_vtd_smoketest_osi.json
    cloe_engine run test_vtd_smoketest_osi.json
}
