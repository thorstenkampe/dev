# shellcheck disable=SC1091,SC2016,SC2154

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

function is_windows {
    [[ $OSTYPE =~ ^(cygwin|msys)$ ]]
}

if is_windows; then
    PATH=/usr/sbin:/usr/bin:$PATH

    function ps {
        procps "$@"
    }
fi

# MAIN CODE STARTS HERE #

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
@test 'groupby - numbers' {
    groupby 'expr $arg % 2' 1 2 3 4

    assert_equal "${groups[0]}" '2 4'
    assert_equal "${groups[1]}" '1 3'
}

@test 'groupby - strings' {
    groupby 'len "$arg"' '' a ab 'a b'

    assert_equal "${groups[0]}" "''"
    assert_equal "${groups[1]}" a
    assert_equal "${groups[2]}" ab
    assert_equal "${groups[3]}" "a\ b"
}

#
@test 'joinby' {
    source test.sh
    run joinby ', ' "${array[@]}"

    assert_output '1, 2, 3, 4, 5, 6, 7, 8, 9'
}

@test 'joinby - single element' {
    run joinby ', ' '0 9'

    assert_output '0 9'
}

@test 'joinby - no element' {
    run joinby ', '

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

    assert_output --regexp '^»1«.»2«.»3«.»4«.»5«.»6«.»7«.»8«.»9«$'
}

#
@test 'showopts' {
    run showopts a:bd: -a 1 -b -c -d

    assert_output --regexp '^valid opts: -a=1, -b.unknown opts: -c.arg missing: -d$'
}

#
@test 'showpath' {
    PATH=/bin:/usr/bin:/usr/local/bin run showpath

    assert_output --regexp '^»/bin«.»/usr/bin«.»/usr/local/bin«$'
}

#
@test 'splitby' {
    splitby ', ' '1, 2, 3, 4, 5, 6, 7, 8, 9'

    assert_equal "${split[*]}" '1 2 3 4 5 6 7 8 9'
}

#
@test 'test_args - no arguments' {
    test='[[ $arg =~ ^(mssql|oracle)$ ]]'
    test_args "$test"

    assert_equal "${#true[@]}" 0
    assert_equal "${#false[@]}" 0
}

@test 'test_args - two true arguments' {
    test='[[ $arg =~ ^(mssql|oracle)$ ]]'
    test_args "$test" mssql oracle

    assert_equal "${true[0]}" 'mssql'
    assert_equal "${true[1]}" 'oracle'
    assert_equal "${#false[@]}" 0
}

@test 'test_args - one true, two false arguments' {
    test='[[ $arg =~ ^(mssql|oracle)$ ]]'
    test_args "$test" mssql oracleX oracleY

    assert_equal "${true[0]}" 'mssql'
    assert_equal "${false[0]}" 'oracleX'
    assert_equal "${false[1]}" 'oracleY'
}

#
@test 'test_file - older than' {
    tmp_file=$(mktemp)
    touch --date '1 hour ago' "$tmp_file"

    # test if file is older than sixty minutes
    test_file "$tmp_file" -mmin +60
    rm "$tmp_file"
}

@test 'test_file - not existing' {
    tmp_file=$(mktemp --dry-run)

    run test_file "$tmp_file"
    assert_failure
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

@test 'zipc/x' {
    mkdir --parent $testdir

    zipc toolbox.sh $testdir/toolbox.sh.zip
    zipx $testdir/toolbox.sh.zip $testdir

    cmp --quiet toolbox.sh $testdir/toolbox.sh
}
