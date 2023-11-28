#!/bin/bash

nbimages=$(find . -iname \*.png | wc -l)
framerate=30

basefolder="$PWD"
parentFolder=$(dirname $basefolder)
localconfigfolder="$basefolder/.config"
logfilename="$localconfigfolder/debug.log"

videoext="mov"
temptimedfile="timed.$videoext"
basefile="base.$videoext"
outputfile="output.$videoext"
outrofile="outro.$videoext"
introfile="intro.$videoext"
vfile="vfile.$videoext"

mkdir -p $localconfigfolder

customlog () {
    now=$(date +"%T")
    echo "$now: $1" >&2
    echo "$now: $1" >> $logfilename
}

getConfigValue () {
    localconfigfile="$localconfigfolder/$1"
    if ! test -f "$localconfigfile"; then
        echo "$2" > $localconfigfile
    fi
    cat $localconfigfile
}


resultfolder=$(getConfigValue targetpath "$basefolder/result")
music=$(getConfigValue music "$parentFolder/musics/alexander-nakarada-forest-walk.mp3")
outrosize=$(getConfigValue outrosize 5 )

touch $logfilename
mkdir -p $resultfolder

d=$(ffmpeg -i $music 2>&1 | grep "Duration" | cut -d ',' -f1 | cut -d ' ' -f4)

h=$(echo $d | cut -d ':' -f1)
m=$(echo $d | cut -d ':' -f2)
s=$(echo $d | cut -d ':' -f3 | cut -d '.' -f1)

soundduration=$((3600*h+60*m+s+1))
vduration=$((soundduration-outrosize))

customlog "starting from $PWD"
customlog "localconfigfolder $localconfigfolder"
customlog "$nbimages in $soundduration seconds ($h:$m:$s)"
customlog "video $vduration seconds + outro $outrosize seconds"


rm $resultfolder/$basefile
rm $resultfolder/$outputfile
rm $temptimedfile
rm $outrofile
rm $vfile

# make outro freeze frame
ffmpeg -framerate $framerate  -loop 1 -i "$(find *.png | tail -n 1)" -t $outrosize \
    -s:v 1440x1080 -c:v prores -profile:v 3 -pix_fmt yuv422p10 $outrofile

# make timelapse video (1 frame per image)
ffmpeg -framerate $framerate -pattern_type glob -i  '*.png' \
   -s:v 1440x1080 -c:v prores -profile:v 3 -pix_fmt yuv422p10 $resultfolder/$basefile

# adapt timelapse video to audio track
ffmpeg -i $resultfolder/$basefile -filter:v "setpts=($vduration/$nbimages)*N/TB" -r $nbimages/$vduration -an $vfile


# merge timelapse and freezeframe
mergelist="
file '$basefolder/$vfile'
file '$basefolder/$outrofile'
"
ffmpeg -f concat -safe 0  -i <(echo "$mergelist") -vcodec copy -acodec copy $temptimedfile

# merge audio and video
ffmpeg -i $temptimedfile -i $music -c copy -map 0:v:0 -map 1:a:0 -shortest $resultfolder/$outputfile