#!/bin/sh

# Regexes
hours_regex="[0-9]+"
minutes_regex="[0-6][0-9]|[1-9]" # Both double- and single-digit values are valid
time_regex="^Time spent:([[:space:]]*$hours_regex[[:space:]]*h)?[[:space:]]*$minutes_regex[[:space:]]*min[[:space:]]*$"

committers_regex="^Committers:([[:space:]]*([[:alnum:]]*)[[:space:]]*)+$"

# Get relevant lines
#message_body="$(git log -1 HEAD --pretty=format:%b)"
message_body="Time spent: 1h 20 min
Committers: jon snow"

time_line="$(printf "%s" "$message_body" | egrep "$time_regex")"
committers_line="$(printf "%s" "$message_body" | egrep "$committers_regex")"

# Convert time to particular units
if [ "$time_line" ] && [[ "$time_line" =~ .*h.*  ]] 
then   
    hours="$(printf "%s" "$time_line" | sed -E "s/[^0-9]*($hours_regex)[[:space:]]*h.*/\1/")"
fi

minutes="$(printf "%s" "$time_line" | sed -E "s/.*h[^0-9]*($minutes_regex)[[:space:]]*min.*/\1/")"
seconds="$(( hours * 3600 + minutes * 60 ))"

# Get Toggl API keys
committers="$(printf "%s" "$committers_line" | sed "s/Committers:[[:space:]]*//")"
handles_array=(${committers})
it="0"

for handle in "${handles_array[@]}"
do
    api_keys["$it"]="$(git config --get toggl.key.$handle)"
done
