# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

# MAIN CODE STARTS HERE #

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash
load /usr/local/libexec/bats-file/load.bash

function setup {
    shopt -ou nounset
    source ./test.sh
    source ./toolbox.sh
    export LANGUAGE=en_US LC_ALL=POSIX
    config=test/test_ini.ini
    testdir=$(mktemp --directory --tmpdir 'tmp XXXXXXXXXX')
    testfile=$(mktemp --tmpdir 'tmp XXXXXXXXXX')
    non_existing_file=$(mktemp --dry-run)
}

function teardown {
    rm -rf "$testdir" "$testfile"
}

##
@test get_group {
    declare -A groupby=( [0 0]=groupby0 )
    groupby0=( 333 444 )

    run tb_get_group '0 0'
    assert_success
    assert_output '333 444'
}

@test 'is_le_version - smaller' {
    tb_is_le_version 1.5 1.10
}

@test 'is_le_version - equal' {
    tb_is_le_version 1.0 1.0
}

@test 'is_le_version - bigger' {
    run tb_is_le_version 1.10 1.5
    assert_failure
}

@test is_sourced {
    tb_is_sourced
}

@test is_tty {
    run tb_is_tty

    assert_failure
    refute_output
}

@test join {
    run tb_join ', ' "${test_array[@]}"

    assert_success
    assert_output '1, 2, 3, 4, 5, 6, 7, 8 8, '
}

@test 'join - single element' {
    run tb_join ', ' '0 9'

    assert_success
    assert_output '0 9'
}

@test 'join - no element' {
    run tb_join ', '

    assert_success
    refute_output
}

@test mailsend-go {
    email_address=noreply@thorstenkampe.de
    msmtpd --port 60587 &
    tb_alias

    run mailsend-go -port 60587 -from $email_address -to $email_address
    assert_success

    kill $!
}

@test 'test_file - older than' {
    touch --date '1 hour ago' "$testfile"

    # test if file is older than sixty minutes
    tb_test_file "$testfile" -mmin +60
}

@test 'test_file - not existing' {
    run tb_test_file "$non_existing_file"
    assert_failure
}

##
@test 'alias - ps' {
    tb_alias
    run ps --pid $$ --format comm=

    assert_success
    assert_output bash
}

#
@test 'arc - zip' {
    tb_arc -c toolbox.sh "$testdir/toolbox.sh.zip"
    tb_arc -x "$testdir/toolbox.sh.zip" "$testdir"

    cmp --quiet toolbox.sh "$testdir/toolbox.sh"
}

@test 'arc - gzip' {
    tb_arc -c toolbox.sh "$testdir/toolbox.sh.tar.gz"
    tb_arc -x "$testdir/toolbox.sh.tar.gz" "$testdir"

    cmp --quiet toolbox.sh "$testdir/toolbox.sh"
}

#
@test gpg {
    cd "$testdir"
    cp "$testfile" "$testfile.old"

    tb_gpg -s password "$testfile"
    rm "$testfile"
    tb_gpg -d password "$testfile.gpg"

    cmp --quiet "$testfile.old" "$testfile"
}

#
@test contains {
    tb_contains 2 1 2 3
}

@test 'contains - not' {
    run tb_contains 22 1 2 3
    assert_failure
}

#
@test 'init - find' {
    tb_init
    run type -p find

    assert_success
    assert_output /usr/bin/find
}

#
@test 'get_section - var' {
    tb_get_section $config connection logging

    assert_equal "$user" test_user
    assert_equal "$password" test_password
    assert_equal "$file" test.log
    assert_equal "$level" debug
}

@test 'get_section - associative array' {
    tb_get_section -a $config connection logging

    assert_equal "${connection[user]}" test_user
    assert_equal "${connection[password]}" test_password
    assert_equal "${logging[file]}" test.log
    assert_equal "${logging[level]}" debug
}

@test 'get_section - ordered array' {
    tb_get_section -o $config connection logging

    assert_equal "${connection[0]}" test_user
    assert_equal "${connection[1]}" test_password
    assert_equal "${logging[0]}" test.log
    assert_equal "${logging[1]}" debug
}

#
@test groupby {
    tb_groupby 'echo ${#arg}' 1 22 333 444

    array="${groupby[1]}[@]"
    assert_equal "${!array}" 1

    array="${groupby[2]}[@]"
    assert_equal "${!array}" 22

    array="${groupby[3]}[*]"
    assert_equal "${!array}" '333 444'
}

#
@test 'log - debug message' {
    run tb_log debug 'test message'

    assert_success
    refute_output
}

#
@test log_to_file {
    tb_init
    run tb_log_to_file "$testdir/test.log" true

    assert_success
    assert_file_exist "$testdir/test.log"
}

#
@test 'map - array' {
    tb_map 'echo ${#arg}' test_array
    assert_equal "${test_array[*]}" '1 1 1 1 1 1 1 3 0'
}

@test 'map - associative array' {
    tb_map 'echo ${#arg}' test_assoc
    assert_equal "${test_assoc[*]}" '0 1 1 1 1 1 1 1 3'
}

#
@test 'parse_opts - valid options (verbose)' {
    tb_parse_opts a:bc -a 1 -b arg1
}

@test 'parse_opts - valid options (silent)' {
    tb_parse_opts :a:bc -a 1 -b arg1
}

@test 'parse_opts - option arguments (verbose)' {
    tb_parse_opts a:bc -a 1 -b arg1

    assert_equal "${opts[a]}" 1
    assert_equal "${opts[b]}" ''
}

@test 'parse_opts - option arguments (silent)' {
    tb_parse_opts :a:bc -a 1 -b arg1

    assert_equal "${opts[a]}" 1
    assert_equal "${opts[b]}" ''
}

@test 'parse_opts - unknown option (verbose)' {
    run tb_parse_opts a:bc -x

    assert_failure
    assert_output --partial ': illegal option -- x'
}

@test 'parse_opts - unknown option (silent)' {
    run tb_parse_opts :a:bc -x

    assert_failure
    refute_output
}

@test 'parse_opts - option requires argument (verbose)' {
    run tb_parse_opts a:bc -a

    assert_failure
    assert_output --partial ': option requires an argument -- a'
}

@test 'parse_opts - option requires argument (silent)' {
    run tb_parse_opts :a:bc -a

    assert_failure
    refute_output
}

@test 'parse_opts - no option' {
    tb_parse_opts a:bc
}

#
@test split {
    tb_split ', ' ', 1, 2, 3, 4, 5, 6, 7, 8, 9, '
    assert_equal "${split[*]}" ' 1 2 3 4 5 6 7 8 9 '
}

#
@test 'test_args - no arguments' {
    test='[[ $arg =~ ^(mssql|oracle)$ ]]'
    tb_test_args "$test"

    assert_equal "${#true[@]}" 0
    assert_equal "${#false[@]}" 0
}

@test 'test_args - two true arguments' {
    test='[[ $arg =~ ^(mssql|oracle)$ ]]'
    tb_test_args "$test" mssql oracle

    assert_equal "${true[0]}" 'mssql'
    assert_equal "${true[1]}" 'oracle'
    assert_equal "${#false[@]}" 0
}

@test 'test_args - one true, two false arguments' {
    test='[[ $arg =~ ^(mssql|oracle)$ ]]'
    tb_test_args "$test" mssql oracleX oracleY

    assert_equal "${true[0]}" 'mssql'
    assert_equal "${false[0]}" 'oracleX'
    assert_equal "${false[1]}" 'oracleY'
}

#
@test 'test_deps - success' {
    tb_test_deps bash
}

@test 'test_deps - failure' {
    run tb_test_deps bash does_not_exist
    assert_failure
}

@test 'test_deps - name with space' {
    chmod +x "$testfile"
    tb_test_deps "$testfile"
}
