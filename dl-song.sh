#!/bin/bash
while IFS="" read -r p || [ -n "$p" ]
do

  trackfile=$PWD/musics/$p.mp3
  if [ ! -f $trackfile ]
  then
     wget https://www.free-stock-music.com/music/$p.mp3 \
      -O $trackfile \
      --header="Accept: text/html" \
      --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" \
      --referer https://www.free-stock-music.com/$p.html 
  fi
done < tracklist



