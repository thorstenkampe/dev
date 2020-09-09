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

@test ps {
    run ps --pid $$ --format comm=
    assert_output bash
    assert_success
}

@test 'no option' {
    run do_options
    refute_output
    assert_success
}

@test 'option help' {
    run do_options -h
    assert_output 'Usage: script.sh [-l <logfile>]'
    assert_success
}

@test 'option log' {
    rm -f script.log
    run do_options -l script.log
    assert_file_exist script.log
    # `refute_output` and `assert_success` don't work because of `exec` in main
    # script
    rm script.log
}

@test 'unknown option' {
    run do_options -x
    assert_output --partial ' -- x'
    assert_failure
}

@test main {
    run main
    refute_output
    assert_success
}
