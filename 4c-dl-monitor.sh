#!/usr/bin/env bash
set -o pipefail
appName=$(basename "${0%'.'*}")
threadURL="$1"

trap quit SIGINT
quit() {
    exit 0
}

printInstances() {
    list=$(pgrep -af "bash $0")
    list=$(echo "$list" | grep -v "$0 list" | grep -v "$$" | awk '{$2=""; $3=""; print $0}')

    if [ -n "$1" ]; then # If invoked internally by the duplicate instance checking function
        list=$(echo "$list" | grep "$1")
    else
        printf "PID\tThread URL\n"
    fi

    echo "$list"
}

# Handle args that aren't URLs
if [ -n "$1" ]; then
    case  "$1" in
        "list")
            printInstances
            exit 0
            ;;
    esac
fi

if [ -z "$threadURL" ]; then
    echo "No URL specified."
    exit 1
fi

# Check if URL is valid
if ! echo "$threadURL" | grep -iP "^https\:\/\/boards\.(?:4chan|4channel)\.org\/[a-z]+?\/(?:thread|res)\/[0-9]+" > /dev/null; then 
    echo "This does not seem to be a valid 4chan thread URL."
    exit 1
fi

# Remove any URL fragment
threadURL=${threadURL%%'#'*}

# Check if we're already monitoring this thread in another instance
instances=$(pgrep -af "bash $0")
instances=$(echo "$instances" | grep -v "$$" | awk '{print $4}') # This is to avoid subshells popping up in the initial pgrep

IFS=$'\n'
read -r -d '' -a watchedURLs <<< "$instances"
numInstances=${#watchedURLs[@]}
((numInstances--)) # To use zero based indexing

for i in $(seq 0 "$numInstances"); do
    currentInstance=${watchedURLs["$i"]}
    currentInstance=${currentInstance%%'#'*} # Remove any URL fragment
    if [[ "$currentInstance" == "$threadURL" ]]; then
        printf "This thread is already being monitored by another instance of %s:\n" "$appName"
        printInstances "$threadURL"
        exit 16
    fi
done

boardName=$(echo "$threadURL" | grep -ioP "^https\:\/\/boards\.(?:4chan|4channel)\.org\/\K[a-z]+?(?=\/)")

refreshTimeout=3540
if [[ $boardName == "b" ]]; then
    refreshTimeout=480
fi

while true; do
    # Check thread status:
    #   - Exit cleanly on 404.
    #   - Exit with error on 403, likely means we got blocked or the URL is somehow invalid
    #   - Do not exit on 5xx errors, just sleep until next iteration, they are usually transient
    status=$(curl --write-out '%{http_code}' --silent --output /dev/null "$threadURL")

    innerResponse=0
    case $status in
        404)
            echo "404 Not Found, exiting."
            exit 0 # Exit with no error, 404/being archived is the natural end state of all 4chan threads
            ;;
        403)
            echo "403 Forbidden, are we blocked? Exiting."
            exit 1
            ;;
        500)
            echo "500 Internal Server Error, site offline?"
            ;;
        502)
            echo "502 Bad Gateway, site offline?"
            ;;
        503)
            echo "503 Service Unavailable, site offline?"
            ;;
        200)
            # Jeremiah Johnson Nod of Approval.gif
            echo "Thread is online! Refreshing...."
            
            bash "$(dirname "$0")/4c-dl.sh" "$threadURL"
            innerResponse=$?
            ;;
    esac

    # Exit with no error if thread is archived
    if [ "$innerResponse" -eq 1  ]; then
        echo "Thread has been archived and will receive no further posts. Exiting."
        exit 0
    fi

    # Sleep for 1 hour (10 minutes for /b/), ±2 min for randomness
    sleepTime=$((refreshTimeout + RANDOM % 240)) 
    echo "Now waiting $sleepTime seconds..."
    sleep "$sleepTime"
done
