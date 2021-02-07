shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

load /usr/local/libexec/bats-assert/load.bash
load /usr/local/libexec/bats-support/load.bash
load /usr/local/libexec/bats-file/load.bash

@test 'help option' {
    shopt -u failglob
    run ./script.sh -h

    assert_output 'Usage: script.sh [-h] [-l <logfile>]'
}

@test 'send email' {
    [[ $OSTYPE == msys ]] && fail 'MSYS not supported'

    local email_address=noreply@thorstenkampe.de
    source script.sh
    msmtpd --port 60587 &

    run send_mail -port 60587 -from $email_address -to $email_address
    kill $!
}

@test 'option log' {
    [[ $OSTYPE == msys ]] && fail 'MSYS not supported'

    rm -f script.log
    run ./script.sh -l script.log

    assert_file_exist script.log
}
