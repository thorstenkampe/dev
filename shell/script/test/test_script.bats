shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash

@test 'help option' {
    shopt -u failglob
    run ./script.sh -h

    assert_success
    assert_output 'Usage: script.sh [-h] [-l <logfile>]'
}
