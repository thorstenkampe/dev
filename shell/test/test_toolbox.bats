# shellcheck disable=SC2016,SC2154,SC2178

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
    export LANGUAGE=en_US
    export LC_ALL=POSIX
    config=test/test_ini.ini
    testdir=$(mktemp --directory)
}

function teardown {
    rm -rf "$testdir"
}

##
@test is_online {
    run tb_is_online

    assert_success
    refute_output
}

@test is_tty {
    run tb_is_tty

    assert_failure
    refute_output
}

@test join {
    run tb_join ', ' "${array[@]}"

    assert_success
    assert_output '1, 2, 3, 4, 5, 6, 7, 8, '
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

@test 'port_reachable - reachable' {
    run tb_port_reachable 8.8.8.8 53
}

@test 'port_reachable - unreachable' {
    run tb_port_reachable localhost 1
    assert_failure
}

@test send_mail {
    email_address=noreply@thorstenkampe.de
    msmtpd --port 60587 &

    run tb_send_mail -port 60587 -from $email_address -to $email_address
    assert_success

    kill $!
}

@test 'test_file - older than' {
    tmp_file=$(mktemp)
    touch --date '1 hour ago' "$tmp_file"

    # test if file is older than sixty minutes
    tb_test_file "$tmp_file" -mmin +60
    rm "$tmp_file"
}

@test 'test_file - not existing' {
    tmp_file=$(mktemp --dry-run)
    run tb_test_file "$tmp_file"

    assert_failure
    assert_file_not_exist "$tmp_file"
}

##
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
    run which find

    assert_success
    assert_output /usr/bin/find
}

@test 'init - ps' {
    tb_init
    run ps --pid $$ --format comm=

    assert_success
    assert_output bash
}

#
@test groupby {
    tb_groupby 'echo ${#arg}' 1 22 333 444

    # shellcheck disable=SC2030
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
    unset "array[8]"
    tb_map 'expr $arg \* 2' array
    # shellcheck disable=SC2031
    assert_equal "${array[*]}" '2 4 6 8 10 12 14 16'
}

@test 'map - associative array' {
    unset "assoc[9]"
    tb_map 'expr $arg \* 2' assoc
    assert_equal "${assoc[*]}" '16 14 12 10 8 6 4 2'
}

#
@test 'parse_opts - valid options' {
    tb_parse_opts a:bc -a 1 -b arg1
}

@test 'parse_opts - option arguments' {
    tb_parse_opts a:bc -a 1 -b arg1

    assert_equal "${opts[a]}" 1
    assert_equal "${opts[b]}" ''
}

@test 'parse_opts - unknown option' {
    run tb_parse_opts a:bc -x

    assert_failure
    assert_output --partial ': illegal option -- x'
}

@test 'parse_opts - option requires argument' {
    run tb_parse_opts a:bc -a

    assert_failure
    assert_output --partial ': option requires an argument -- a'
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

# ini #
@test section_to_array {
    tb_section_to_array $config connection logging

    assert_equal "${connection[user]}" test_user
    assert_equal "${connection[password]}" test_password
    assert_equal "${logging[file]}" test.log
    assert_equal "${logging[level]}" debug
}

@test 'section_to_array - ordered' {
    tb_section_to_array -o $config connection logging

    assert_equal "${connection[0]}" test_user
    assert_equal "${connection[1]}" test_password
    assert_equal "${logging[0]}" test.log
    assert_equal "${logging[1]}" debug
}

@test section_to_var {
    tb_section_to_var $config connection logging

    assert_equal "$user" test_user
    assert_equal "$password" test_password
    assert_equal "$file" test.log
    assert_equal "$level" debug
}
