#!/bin/sh

yesno() {
    while :
    do
        printf "%s" "$*"
        read decision

        case "$decision" in
            y|Y|Yes|yes|YES|'')
                return 0
                ;;
            n|N|No|no|NO)
                return 1
                ;;
            *)
                printf "[ERROR] That doesn't seem like a possible choice."
                ;;
        esac
    done
}
