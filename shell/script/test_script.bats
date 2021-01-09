shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

if [[ $OSTYPE == msys ]]; then
    prefix=/f/cygwin
fi

load "${prefix-}/usr/local/libexec/bats-assert/load.bash"
load "${prefix-}/usr/local/libexec/bats-support/load.bash"

@test 'parse options' {
    source script.sh
    run parse_opts a:bc -a 1 -b arg1

    assert_success
    refute_output
}

@test 'test options set' {
    source script.sh
    parse_opts a:bc -a 1 -b arg1

    set_opt a
    set_opt b
    run set_opt c
    assert_failure
}

@test 'option arguments' {
    source script.sh
    parse_opts a:bc -a 1 -b arg1

    # shellcheck disable=SC2154
    assert_equal "${opts[a]}" 1
    assert_equal "${opts[b]}" ''
}

@test 'unknown option' {
    LANGUAGE=en_US run ./script.sh -x

    assert_failure
    assert_output --partial ': illegal option -- x'
}

@test 'option requires argument' {
    source script.sh
    LANGUAGE=en_US run parse_opts a:bc -a

    assert_failure
    assert_output --partial ': option requires an argument -- a'
}

@test 'help option' {
    shopt -u failglob
    run ./script.sh -h

    assert_success
    assert_output 'Usage: script.sh [-h]'
}

@test 'no option' {
    run ./script.sh

    assert_success
    refute_output
}

@test ps {
    source script.sh
    run ps --pid $$ --format comm=

    assert_output bash
    assert_success
}
