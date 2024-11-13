#!/usr/bin/env bash
#
# 4c-dl - Download all media from a 4chan thread
#
# Exit codes:
#   0 - All is well
#   1 - Fatal error, invalid or no URL given
#   2 - Thread has been archived
#

set -o pipefail
downloadRoot="$HOME/Downloads/.lewds"
threadURL="$1"

if [ -z "$threadURL" ]; then # No pants, no service
    echo "No URL specified."
    exit 1
fi

# Check if URL is valid
if ! echo "$threadURL" | grep -iP "^https\:\/\/boards\.(?:4chan|4channel)\.org\/[a-z]+?\/(?:thread|res)\/[0-9]+" > /dev/null; then 
    echo "This does not seem to be a valid 4chan thread URL."
    exit 1
fi

# Get board name and thread number from URL, then build final download path
boardName=$(echo "$threadURL" | grep -ioP "^https\:\/\/boards\.(?:4chan|4channel)\.org\/\K[a-z]+?(?=\/)")
threadNumber=$(echo "$threadURL" | grep -ioP "^https\:\/\/boards\.(?:4chan|4channel)\.org\/[a-z]+?\/(?:thread|res)\/\K[0-9]+")
downloadPath="$downloadRoot/$boardName/$threadNumber"

mkdir -p "$downloadPath" && cd "$downloadPath" || exit

# Explanation of the following wget command:
#  -A accepts all images, videos and audio
#  -R rejects all thumbnails and favicons
#  --reject-regex makes sure we reject the banner images
wget -r -np -nH -nd -nc -e robots=off -A "jpg,jpeg,png,webp,gif,webm,mp4,mp3,m4a" -R "*s.jpg,*s.jpeg,*s.png,*s.webp,4chan-icon-*.png" --regex-type pcre --reject-regex="[A-Fa-f0-9]{40}\.(?:gif|png|jpg|jpeg|webp)$" -H -q --show-progress "$threadURL"

if [ -f "$downloadPath/archived.gif" ]; then
    rm "$downloadPath/archived.gif"
    exit 2 # Thread archived, exit 2, 4c-dl-mon picks this up and echoes appropriately
else
    exit 0 # wget always returns 8 because it tries to follow links that return 403, there is no way to stop it from doing so
fi
