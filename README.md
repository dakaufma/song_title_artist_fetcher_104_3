# Description

Simple python BeautifulSoup script for scraping the playlist of 104.3 (good rock station in Pasadena)


# Requirements

Tested on Arch Linux; requires python 3 with BeautifulSoup4 and lxml packages 
(python-beautifulsoup4 and python-lxml I think)


# Useful bash snippits

### Run every 30 minutes and save results

    while true; do python fetch.py | tee -a songlist; echo; sleep 30m; done

### Find unique entries/entry counts

    cat songlist | sort | uniq > list
    cat songlist | sort | uniq -c | sort -n

Note that the counts may be a little off because we're parsing the playlist 
every 30 minutes -> could miss or double-count songs. There is probably a 
slight bias towards missing short songs and double-counting long songs.

### Parse the songlist and use youtube-dl to fetch songs/vidoes

Requires youtube-dl (package youtube-dl)

    while read line
    do
    TITLE=$(echo $line | sed "s/([\"']//g" | sed "s/[\"'],.*//");
    echo "$TITLE";
    youtube-dl "ytsearch:${TITLE}";
    done < list

### Fetch lyrics with glyrc

Requires glyr (package glyr-git from the AUR)

    while read line
    do
    TITLE=$(echo $line | sed "s/([\"']//g" | sed "s/[\"'],.*//");
    ARTIST=$(echo $line | sed "s/.*[\"'], [\"']//" | sed "s/[\"'])//");
    CLEAN_TITLE=$(echo "$TITLE" | sed "s/(.*)//g" | sed "s/\\[.*\\]//g");
    CLEAN_ARTIST=$(echo "$ARTIST" | sed "s/(.*)//g" | sed "s/\\[.*\\]//g");
    echo -e "${CLEAN_TITLE}\t${CLEAN_ARTIST}";
    glyrc lyrics -a "${CLEAN_ARTIST}" -t "${CLEAN_TITLE}" --parallel 5 --number 1
    done < list
