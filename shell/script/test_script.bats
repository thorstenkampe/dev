#! /usr/bin/env bats

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash

source script.sh
shopt -ou nounset
shopt -u failglob

#
@test 'log error message' {
    run log ERROR 'test message'

    assert_success
    assert_output 'ERROR: test message'
}

@test 'no option' {
    _args=(arg1 arg2)
    run parse_options a:bc

    assert_success
    refute_output
}

@test 'standard options' {
    _args=(-a 1 -b arg1 arg2)

    run parse_options a:bc

    assert_success
    refute_output
}

@test 'test options' {
    _args=(-a 1 -b arg1 arg2)
    parse_options a:bc

    is_option_set a
    is_option_set b
    run is_option_set c
    assert_failure
}

@test 'test option arguments' {
    # $ script.sh -a 1 -b arg1 arg2)
    _args=(-a 1 -b arg1 arg2)
    parse_options a:bc

    assert_equal "${options[a]}" 1
    assert_equal "${options[b]}" ''
}

@test 'unknown option' {
    _args=(-x)
    LANGUAGE=en_EN:en run parse_options a:bc

    assert_failure
    assert_output --partial ': illegal option -- x'
}

@test 'option requires argument' {
    _args=(-a)
    LANGUAGE=en_EN:en run parse_options a:bc

    assert_failure
    assert_output --partial ': option requires an argument -- a'
}
