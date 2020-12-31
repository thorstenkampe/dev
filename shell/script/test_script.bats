#! /usr/bin/env bats

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash

function setup {
    # shellcheck disable=SC1091
    source script.sh
    shopt -ou nounset
    shopt -u failglob

    export LANGUAGE=en_US
    std_params=(-a 1 -b arg1)
}

#
@test 'parse options' {
    run parse_opts a:bc "${std_params[@]}"

    assert_success
    refute_output
}

@test 'test options set' {
    parse_opts a:bc "${std_params[@]}"

    has_opt a
    has_opt b
    run has_opt c
    assert_failure
}

@test 'option arguments' {
    parse_opts a:bc "${std_params[@]}"

    # shellcheck disable=SC2154
    assert_equal "${opts[a]}" 1
    assert_equal "${opts[b]}" ''
}

#
@test 'unknown option' {
    run parse_opts a:bc -x

    assert_failure
    assert_output --partial ': illegal option -- x'
}

@test 'option requires argument' {
    # shellcheck disable=SC2034
    run parse_opts a:bc -a

    assert_failure
    assert_output --partial ': option requires an argument -- a'
}

#
@test 'log error message' {
    run log ERROR 'test message'

    assert_success
    assert_output 'ERROR: test message'
}
