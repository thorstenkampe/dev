# shellcheck disable=SC2016,SC2154

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

# MAIN CODE STARTS HERE #

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash
load /usr/local/libexec/bats-file/load.bash

function setup {
    shopt -ou nounset
    source test.sh
    source toolbox.sh
    export LANGUAGE=en_US
    config=test/test_ini.ini
    testdir=$(mktemp --directory)
}

function teardown {
    rm -rf "$testdir"
}

##
@test 'has_section - existing section' {
    has_section $config connection
}

@test 'has_section - not existing section' {
    run has_section $config no_connection
    assert_failure
}

@test 'has_section - existing key' {
    has_section $config connection user
}

@test 'has_section - not existing key' {
    run has_section $config connection no_user
    assert_failure
}

@test is_tty {
    run is_tty

    assert_failure
    refute_output
}

@test set_opt {
    parse_opts a:bc -a 1 -b arg1

    set_opt a
    set_opt b
    run set_opt c
    assert_failure
}

@test splitby {
    splitby ', ' '1, 2, 3, 4, 5, 6, 7, 8, 9'
    assert_equal "${splitby[*]}" '1 2 3 4 5 6 7 8 9'
}

@test timestamp {
    run timestamp

    assert_success
    assert_output --regexp '^[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}$'
}

##
@test amap {
    amap 'expr $arg + 2' array
    assert_equal "${array[*]}" '3 4 5 6 7 8 9 10 11'
}

#
@test 'arc - zip' {
    arc -c toolbox.sh "$testdir/toolbox.sh.zip"
    arc -x "$testdir/toolbox.sh.zip" "$testdir"

    cmp --quiet toolbox.sh "$testdir/toolbox.sh"
}

@test 'arc - gzip' {
    arc -c toolbox.sh "$testdir/toolbox.sh.tar.gz"
    arc -x "$testdir/toolbox.sh.tar.gz" "$testdir"

    cmp --quiet toolbox.sh "$testdir/toolbox.sh"
}

#
@test contains {
    contains 2 1 2 3
}

@test 'contains - not' {
    run contains 22 1 2 3

    assert_failure
}

#
@test 'init - find' {
    init
    run which find

    assert_success
    assert_output /usr/bin/find
}

@test 'init - ps' {
    init
    run ps --pid $$ --format comm=

    assert_success
    assert_output bash
}

#
@test joinby {
    run joinby ', ' "${array[@]}"

    assert_success
    assert_output '1, 2, 3, 4, 5, 6, 7, 8, 9'
}

@test 'joinby - single element' {
    run joinby ', ' '0 9'

    assert_success
    assert_output '0 9'
}

@test 'joinby - no element' {
    run joinby ', '

    assert_success
    refute_output
}

#
@test 'log - info message' {
    run log info 'test message'

    assert_success
    refute_output
}

#
@test log_to_file {
    init
    run log_to_file "$testdir/test.log" true

    assert_success
    assert_file_exist "$testdir/test.log"
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
@test send_mail {
    email_address=noreply@thorstenkampe.de
    msmtpd --port 60587 &

    run send_mail -port 60587 -from $email_address -to $email_address
    assert_success

    kill $!
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
    assert_file_not_exist "$tmp_file"
}

# ini #
@test section_to_array {
    section_to_array $config connection logging

    assert_equal "${connection[user]}" test_user
    assert_equal "${connection[password]}" test_password
    assert_equal "${logging[file]}" test.log
    assert_equal "${logging[level]}" debug
}

@test 'section_to_array - ordered' {
    section_to_array -o $config connection logging

    assert_equal "${connection[0]}" test_user
    assert_equal "${connection[1]}" test_password
    assert_equal "${logging[0]}" test.log
    assert_equal "${logging[1]}" debug
}

@test section_to_var {
    section_to_var $config connection logging

    assert_equal "$user" test_user
    assert_equal "$password" test_password
    assert_equal "$file" test.log
    assert_equal "$level" debug
}
