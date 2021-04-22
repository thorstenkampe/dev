shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash

@test 'help option' {
    shopt -u failglob
    run ./script.sh -h

    assert_success
    assert_line --index 0 'Usage: script.sh [-l <logfile>]'
    assert_line --index 1 Options:
    assert_line --index 2 '  -l <logfile>  Log to file'
    assert_line --index 3 '  -h            Show help'
    assert_line --index 4 '  -d            Show debug and trace messages'
}
