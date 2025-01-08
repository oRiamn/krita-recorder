#!/bin/bash

musicpath=$PWD/musics

mkdir -p $musicpath


dlcredits () {

    sumarypage=https://www.free-stock-music.com/$1.html
    page=$(wget -qO- $sumarypage)

    echo "$page" \
    | sed -n "/downloadFile('/,/')/p" \
    | sed -e 's/<[^>]*>//g' \
    | sed -e 's/&nbsp;//g' \
    | cut -d '|' -f1 \
    | head -n 1 > $musicpath/$1.mp3.info
    
    echo "$page" \
    | sed -n "/<div id='dialog'/,/<\/div>/p" \
    | sed -n "/<div class='creditTextExample'>/,/<\/div>/p" \
    | sed 's/<br\/>/\
    /g' | sed -e 's/<[^>]*>//g' \
    | sed -e 's/^[ \t]*//' \
    | sed -r '/^\s*$/d' >> $musicpath/$1.mp3.credit
    
    echo "$page" \
    | sed -n "/class='trackDetailsCont'/,/<\/span>/p" \
    | sed -e 's/<[^>]*>//g' \
    | sed -e 's/&nbsp;//g' \
    | cut -d '|' -f1 \
    | head -n 1 \
    | sed -e 's/^[ \t]*//' \
    | sed -e 's/^/Title:/;' > $musicpath/$1.mp3.info
    
    echo "$page" \
    |  sed -n "/<div class='trackArtistPropertiesCont'>/,/<\/div>/p" \
    | sed 's/<[bh]r\/>/\
    /g' | sed -e 's/<[^>]*>//g' \
    | sed -e 's/&nbsp;//g' \
    | sed -e 's/: /:/g' \
    | sed -e 's/^[ \t]*//' \
    | sed -r '/^\s*$/d' \
    | grep -v playlist >> $musicpath/$1.mp3.info


   trackuri=$(echo "$page" \
   | grep -Eoi '<audio[^>]+>' \
   |  grep -Eo "id='mainPlayer' src='/[a-zA-Z0-9./?=_%:-]*" \
   | grep -Eo "/[a-zA-Z0-9./?=_%:-]*")

    wget  https://www.free-stock-music.com/$trackuri \
     -O $2 \
     --header="Accept: text/html" \
     --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" \
     --referer $sumarypage
}


while IFS="" read -r p || [ -n "$p" ]
do  
    trackfile=$musicpath/$p.mp3
    if [ ! -f $trackfile ]
    then

        echo "$p"
        dlcredits $p $trackfile
    fi
done < tracklist