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

@test send_mail {
    source script.sh
    email_address=noreply@thorstenkampe.de
    msmtpd --port 60587 &

    run send_mail -port 60587 -from $email_address -to $email_address
    assert_success

    kill $!
}
