#! /usr/bin/env bats

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash

function setup {
    # shellcheck disable=SC1091
    source script.sh
    shopt -ou nounset
    shopt -u failglob

    _params=(-a 1 -b arg1 arg2)
}

#
@test 'parse options' {
    run parse_options a:bc

    assert_success
    refute_output
}

@test 'test options set' {
    parse_options a:bc

    is_option_set a
    is_option_set b
    run is_option_set c
    assert_failure
}

@test 'option arguments' {
    parse_options a:bc

    # shellcheck disable=SC2154
    assert_equal "${opts[a]}" 1
    assert_equal "${opts[b]}" ''
}

@test 'arguments' {
    parse_options a:bc

    # shellcheck disable=SC2154
    assert_equal "${args[0]}" arg1
    assert_equal "${args[1]}" arg2
}

#
@test 'unknown option' {
    _params=(-x)
    LANGUAGE=en_EN:en run parse_options a:bc

    assert_failure
    assert_output --partial ': illegal option -- x'
}

@test 'option requires argument' {
    # shellcheck disable=SC2034
    _params=(-a)
    LANGUAGE=en_EN:en run parse_options a:bc

    assert_failure
    assert_output --partial ': option requires an argument -- a'
}

#
@test 'log error message' {
    run log ERROR 'test message'

    assert_success
    assert_output 'ERROR: test message'
}
