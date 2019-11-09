#! /usr/bin/env bats

shopt -os nounset pipefail errexit

#
load /usr/local/bin/bats-modules/bats-support/load.bash
load /usr/local/bin/bats-modules/bats-assert/load.bash

#
source script.sh

@test 'no option' {
    run do_options
    refute_output
    assert_success
}

@test 'option h' {
    run do_options -h
    assert_output 'Usage: script.sh'
    assert_success
}

@test 'option x' {
    run do_options -x
    assert_output --partial ': illegal option -- x'
    assert_failure
}
