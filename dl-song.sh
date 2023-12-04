#!/bin/bash

dlcredits () {
    
    page=$(curl  dlcredits https://www.free-stock-music.com/$1.html)
    
    echo "$page" \
    | sed -n "/<div id='dialog'/,/<\/div>/p" \
    | sed -n "/<div class='creditTextExample'>/,/<\/div>/p" \
    | sed 's/<br\/>/\
    /g' | sed -e 's/<[^>]*>//g' \
    | sed -e 's/^[ \t]*//' \
    | sed -r '/^\s*$/d' > $PWD/musics/$1.mp3.credit
    
    echo "$page" \
    | sed -n "/class='trackDetailsCont'/,/<\/span>/p" \
    | sed -e 's/<[^>]*>//g' \
    | sed -e 's/&nbsp;//g' \
    | cut -d '|' -f1 \
    | head -n 1 \
    | sed -e 's/^[ \t]*//' \
    | sed -e 's/^/Title:/;' > $PWD/musics/$1.mp3.info
    
    echo "$page" \
    |  sed -n "/<div class='trackArtistPropertiesCont'>/,/<\/div>/p" \
    | sed 's/<[bh]r\/>/\
    /g' | sed -e 's/<[^>]*>//g' \
    | sed -e 's/&nbsp;//g' \
    | sed -e 's/: /:/g' \
    | sed -e 's/^[ \t]*//' \
    | sed -r '/^\s*$/d' \
    | grep -v playlist >> $PWD/musics/$1.mp3.info
}


while IFS="" read -r p || [ -n "$p" ]
do
    
    trackfile=$PWD/musics/$p.mp3
    if [ ! -f $trackfile ]
    then
        dlcredits $p
        wget https://www.free-stock-music.com/music/$p.mp3 \
        -O $trackfile \
        --header="Accept: text/html" \
        --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" \
        --referer https://www.free-stock-music.com/$p.html
    fi
done < tracklist