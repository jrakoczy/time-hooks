#!/bin/sh
. ./auxiliary.sh

# Regexes
hours_regex="[0-9]+"
minutes_regex="[0-6][0-9]|[1-9]" # Both double- and single-digit values are valid
time_regex="^Time spent:([[:space:]]*$hours_regex[[:space:]]*h)?[[:space:]]*$minutes_regex[[:space:]]*min[[:space:]]*$"

committers_regex="^Committers:([[:space:]]*([[:alnum:]]*)[[:space:]]*)+$"

# Get relevant lines
#subject_line="$(git log -1 HEAD --pretty=format:%s)"
#message_body="$(git log -1 HEAD --pretty=format:%b)"
message_body="Time spent: 1h 20 min
Committers: jrakoczy"

subject_line="Final test"
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

project_id="$(git config --get toggl.pid 2>/dev/null)"  
if [ ! "$project_id" ]
then 
    printf "\n[ERROR] A project id is not defined."
    yesno_message="$(printf "\nWould you like to add a project id? (Y/n): ")"
    yesno "$yesno_message" || { printf "Couldn't add a time entry."; exit 1; }
    printf "\nProject id [$handle]: " 
    read project_id
fi

send_request() {
    local header="Content-Type: application/json"
    local request_url="https://www.toggl.com/api/v8/time_entries"
    local auth="$1:api_token"
    
    # Data
    local start_time="$(date +"%FT%T+02:00" --date "-$seconds sec")"
    echo "$start_time"
    local data="
                {
                    \"time_entry\":
                    {
                        \"description\":\"$subject_line\",
                        \"duration\":$seconds,
                        \"start\":\"$start_time\",
                        \"pid\":$project_id,
                        \"created_with\":\"curl\"
                    }
                }"
    
    if curl -v -u "$auth" -H "$header" -d "$data" -X POST "$request_url" >/dev/null 2>&1
    then
        printf "Time entry added to the project." 
    else
        printf "[ERROR] Couldn't access Toggl API. Time entry hasn't been added."
        exit 1
    fi             
}


for handle in "${handles_array[@]}"
do
    api_key="$(git config --get toggl.key.$handle 2>/dev/null)"  
    if [ ! "$api_key" ]
    then 
        printf "\n[ERROR] There's no API key for handle: %s" "$handle"
        yesno_message="$(printf "\nWould you like to add a key to the handle? (Y/n): ")"
        yesno "$yesno_message" || continue
        printf "\nAPI key [$handle]: " 
        read api_key 
    fi

    send_request "$api_key"
done


