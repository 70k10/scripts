#!/bin/bash
# vim: set sw=4 sts=4 et :
# Author(s): Nirbheek Chauhan <nirbheek.chauhan@gmail.com>
#
# License: Public Domain

##############
## Settings ##
##############

# Order in which to check for running browsers to open the url in
# Separated by : is the command to call with arguments (if any)
# Ex: ORDER=("firefox:firefox -new-tab" "epiphany:~/bin/epiphany")
# if unspecified, `type` is used to detect it.
ORDER=("chromium" "chromium-bin" "firefox:firefox -new-tab" "opera" )

# Spawning order if none of the above browsers are running
# This should simply contain paths with arguments (if any)
SPAWN=("chromium" "chromium-bin" "opera" "firefox")

#################
## Preparation ##
#################

die() {
    echo "$@" 1>&2
    exit 1
}

test -n "$1" || die "No url specified."
test -n "$USER" || die "\$USER blank; bad environment?"
type ps &>/dev/null || die "'ps' not found; bad OS?"

URL=$1

###############
## Functions ##
###############

is_running() {
    test -n "$1" || die "wtf, pass something to me!"
    name=$1
    # This test can easily give false positives.
    # Probably need to refine $name somehow
    test $(ps -U ${USER} -u ${USER} u | grep "${name}" | wc -l) -ge 2 && return 0
    return 1
}

run_browser() {
    test -n "$@" || die "wtf, pass something to me!"
    cmd=$@
    ${cmd} &
    pid=$!
    is_running "${pid}"
}

##########
## Work ##
##########

for each in "${ORDER[@]}"; do
    if [[ ${each} =~ : ]]; then
        browser=$(cut -f1 -d: <<<"${each}")
        path=$(cut -f2 -d: <<<"${each}")
    else
        browser=${each}
        path=$(type -P "${each}")
    fi

    if is_running "$browser"; then
        ${path} "${URL}"
        ret=$?
        if test "${ret}" == 0; then
            echo "Opened in existing '${browser}' as '${path} ${URL}'"
            exit 0
        else
            echo "Failed to run '${browser}' as '${path} ${URL}'; trying next..."
        fi
    fi
done

for path in "${SPAWN[@]}"; do
    run_browser "${path} ${URL}" && echo "Ran '${path}'" && exit 0
    echo "Failed to run browser '${path}'; trying next..."
done

echo "Unable to perform as expected; please spank me :("
exit 1
