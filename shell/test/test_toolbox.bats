# shellcheck disable=SC1091,SC2154

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash

function setup {
    source toolbox.sh
    export LANGUAGE=en_US
    testdir=tmp
}

function teardown {
    rm -rf "$testdir"
}

#
@test 'setup - ps' {
    run ps --pid $$ --format comm=

    assert_output bash
}

@test 'setup - find' {
    PATH=/cygdrive/c/WINDOWS/system32:/c/WINDOWS/system32:$PATH
    source toolbox.sh
    run which find

    assert_output /usr/bin/find
}

#
@test 'arcc/x - zip' {
    mkdir --parent $testdir

    arcc toolbox.sh $testdir/toolbox.sh.zip
    arcx $testdir/toolbox.sh.zip $testdir

    cmp --quiet toolbox.sh $testdir/toolbox.sh
}

@test 'arcc/x - gzip' {
    mkdir --parent $testdir

    arcc toolbox.sh $testdir/toolbox.sh.tar.gz
    arcx $testdir/toolbox.sh.tar.gz $testdir

    cmp --quiet toolbox.sh $testdir/toolbox.sh
}

#
@test 'join_by' {
    source test.sh
    run join_by ', ' "${array[@]}"

    assert_output '1, 2, 3, 4, 5, 6, 7, 8, 9'
}

@test 'join_by - single element' {
    run join_by ', ' '0 9'

    assert_output '0 9'
}

@test 'join_by - no element' {
    run join_by ', '

    refute_output
}

#
@test 'log - info message' {
    run log INFO 'test message'

    refute_output
}

@test 'log - verbosity info message' {
    verbosity=INFO run log INFO 'test message'

    assert_output 'INFO: test message'
}

#
@test 'parse_opts - valid options' {
    parse_opts a:bc -a 1 -b arg1
}

@test 'parse_opts - option arguments' {
    parse_opts a:bc -a 1 -b arg1

    # shellcheck disable=SC2154
    assert_equal "${opts[a]}" 1
    assert_equal "${opts[b]}" ''
}

@test 'parse_opts - unknown option' {
    run parse_opts a:bc -x

    assert_failure
    assert_output --partial ': illegal option -- x'
}

@test 'parse_opts - option requires argument' {
    run parse_opts a:bc -a

    assert_failure
    assert_output --partial ': option requires an argument -- a'
}

@test 'parse_opts - no option' {
    parse_opts a:bc
}

#
@test 'pprint' {
    source test.sh
    run pprint assoc

    assert_output '9: 9, h: 8, g: 7, f: 6, e: 5, d: 4, c: 3, b: 2, a: 1'
}

@test 'pprint - empty value' {
    # shellcheck disable=SC2034
    declare -gA myassoc=([a]='')
    run pprint myassoc

    assert_output "a: ''"
}

#
@test 'set_opt' {
    parse_opts a:bc -a 1 -b arg1

    set_opt a
    set_opt b
    run set_opt c
    assert_failure
}

#
@test 'showargs' {
    source test.sh
    run showargs "${array[@]}"

    assert_output --regexp '^>1<.>2<.>3<.>4<.>5<.>6<.>7<.>8<.>9<$'
}

#
@test 'showopts' {
    run showopts a:bd: -a 1 -b -c -d

    assert_output --regexp '^valid opts: -a=1, -b.unknown opts: -c.arg missing: -d$'
}

#
@test 'showpath' {
    PATH=/bin:/usr/bin:/usr/local/bin run showpath

    assert_output --regexp '^>/bin<.>/usr/bin<.>/usr/local/bin<$'
}

#
@test 'split_by' {
    split_by ', ' '1, 2, 3, 4, 5, 6, 7, 8, 9'

    assert_equal "${split[*]}" '1 2 3 4 5 6 7 8 9'
}

#
@test 'test_args - no arguments' {
    # shellcheck disable=SC2016
    local test='[[ $arg =~ ^(mssql|oracle)$ ]]'

    test_args "$test"
}

@test 'test_args - two true arguments' {
    # shellcheck disable=SC2016
    local test='[[ $arg =~ ^(mssql|oracle)$ ]]'

    test_args "$test" mssql oracle
}

@test 'test_args - one true, one false arguments' {
    # shellcheck disable=SC2016
    local test='[[ $arg =~ ^(mssql|oracle)$ ]]'

    run test_args "$test" mssql oracleX
    assert_failure
    assert_output oracleX
}

#
@test 'test_file - older than' {
    local tmp_file
    tmp_file=$(mktemp)
    touch --date '1 hour ago' "$tmp_file"

    # test if file is older than sixty minutes
    test_file "$tmp_file" -mmin +60
    rm "$tmp_file"
}

@test 'test_file - not existing' {
    local tmp_file
    tmp_file=$(mktemp --dry-run)

    run test_file "$tmp_file"
    assert_failure
}

#
@test 'zipc/x' {
    mkdir --parent $testdir

    zipc toolbox.sh $testdir/toolbox.sh.zip
    zipx $testdir/toolbox.sh.zip $testdir

    cmp --quiet toolbox.sh $testdir/toolbox.sh
}
