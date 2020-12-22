#! /usr/bin/env bats

export LANGUAGE=en_EN:en

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

@test 'no option' {
    _args=(arg1 arg2)
    run parse_options a:bc
    refute_output
    assert_success
}

@test 'standard options' {
    # $ script.sh -a 1 -b
    _args=(-a 1 -b arg1 arg2)

    run parse_options a:bc
    refute_output
    assert_success

    parse_options a:bc
    assert_equal "${options[a]}" 1
    assert_equal "${options[b]}" ''
    run test -v options[c]  # `-v` for associative arrays in bash 4.3
    assert_failure
}

@test 'unknown option' {
    _args=(-x)
    run parse_options a:bc
    assert_output --partial ': illegal option -- x'
    assert_failure
}

@test 'option requires argument (I)' {
    _args=(-a)
    run parse_options a:bc
    assert_output --partial ': option requires an argument -- a'
    assert_failure
}

@test 'option requires argument (II)' {
    _args=(-a -b)
    run parse_options a:bc
    assert_output --partial ': option requires an argument -- a'
    assert_failure
}
