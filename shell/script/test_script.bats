#! /usr/bin/env bats

load /usr/local/bin/bats-modules/bats-support/load.bash
load /usr/local/bin/bats-modules/bats-assert/load.bash

source script.sh
shopt -ou nounset

#
@test log {
    run log ERROR 'test message'
    assert_output --regexp '<13>.* ERROR: test message'
    assert_success
}

@test 'no option' {
    run do_options
    refute_output
    assert_success
}

@test 'option help' {
    run do_options -h
    assert_output 'Usage: script.sh'
    assert_success
}

@test 'unknown option' {
    run do_options -x
    assert_output --partial ': illegal option -- x'
    assert_failure
}
