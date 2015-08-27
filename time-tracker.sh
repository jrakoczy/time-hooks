#!/bin/sh

# Regexps
hours_regex="([0-9]+)"
minutes_regex="[0-6][0-9]|[1-9]" # Both double- and single-digit values are valid
time_regex="^([[:space:]]*$hours_regex[[:space:]]*h)?[[:space:]]*($minutes_regex)[[:space:]]*min[[:space:]]*$"

committers_regex="^([[:space:]]*([[:alnum:]])[[:space:]]*)+$"

# Functions
get_time(){
    printf "\nEnter time spent separating time units with h (hours) and min (minutes)."
    printf "\nWhitespaces are omitted."
    printf "\nEg:  1 h 30 min"
    printf "\nTime spent: " 
    read time_spent

    [[  "$time_spent" =~ $time_regex ]] || return 1
    time_spent="$(printf "%s" "$time_spent" | sed -e 's/\s\{2,\}/ /g')"
}

get_committers() {
    printf "\nEnter (a) handle(s) of committer(s) working on the commit."
    printf "\nIn case there were more than one committer separate handles with whitespaces."
    printf "\nEg: jondoe marthastew" 
    printf "\nCommitters: "
    read committers

    [[ "$committers" =~ $committers_regex ]] || return 1
    committers="$(printf "%s" "$committers" | sed -e 's/\s\{2,\}/ /g')"
}

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

# Main loop
while :
do     
    while : 
    do
        get_time && break || printf "\n[ERROR] Invalid time format.\nPlease re-enter the data.\n"
    done

    while :
    do 
        get_committers && break || printf "\n[ERROR] Invalid handle(s) format. Please re-enter the data.\n"
    done

    time_message=$(printf "\nTime spent: ${time_spent}")
    committers_message=$(printf "\nCommitters: ${committers}")
    reenter_message=$(printf "\nDo you want to proceed? (Y/n):")
    yesno_message="${time_message}${committers_message}${reenter_message}"
    
    if  yesno "$yesno_message"
    then
        printf "${time_message}${committers_message}" >> $1 || printf "\n[ERROR] Couldn't append to the commit message."
        break
    fi
done       
