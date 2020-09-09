#! /usr/bin/env bats

load /usr/local/bin/bats-modules/bats-support/load.bash
load /usr/local/bin/bats-modules/bats-assert/load.bash
load /usr/local/bin/bats-modules/bats-file/load.bash

source script.sh
shopt -ou nounset
shopt -u failglob

#
@test 'log error message' {
    run log ERROR 'test message'
    assert_output --regexp '.* ERROR: test message'
    assert_success
}

@test main {
    run main
    refute_output
    assert_success
}
