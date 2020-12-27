#! /usr/bin/env bats

export LANGUAGE=en_EN:en

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
    # $ script.sh -a 1 -b arg1 arg2)
    _args=(-a 1 -b arg1 arg2)

    run parse_options a:bc

    assert_success
    refute_output

    parse_options a:bc
    assert_equal "${options[a]}" 1
    assert_equal "${options[b]}" ''

    run test -v options[c]  # `-v` for associative arrays in bash 4.3
    assert_failure
}

@test 'unknown option' {
    _args=(-x)
    run parse_options a:bc

    assert_failure
    assert_output --partial ': illegal option -- x'
}

@test 'option requires argument' {
    _args=(-a)
    run parse_options a:bc

    assert_failure
    assert_output --partial ': option requires an argument -- a'
}
