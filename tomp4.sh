#!/bin/bash
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

finaltimelapse="timelapse.mp4"

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
music=$(getConfigValue music "$parentFolder/musics/ethereal88-hopes-and-dreams.mp3")
outrosize=$(getConfigValue outrosize 5 )



touch $logfilename
mkdir -p $resultfolder

nbimages=$(find $resultfolder -iname \*.png | wc -l)
framerate=30


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
rm $resultfolder/$finaltimelapse
rm $resultfolder/$outputfile
rm $temptimedfile
rm $outrofile
rm $vfile


lastimage=$(find $resultfolder/*.png | tail -n 1)

customlog "make outro freeze frame with $lastimage in $outrofile" 

# make outro freeze frame
ffmpeg -framerate $framerate  -loop 1 -i $lastimage -t $outrosize \
    -c:v prores -profile:v 3 -pix_fmt yuv422p10 $outrofile


customlog "timelapse video with $nbimages (1 frame per image)" 
# make timelapse video (1 frame per image)
ffmpeg -framerate $framerate -pattern_type glob -i  "$resultfolder/*.png" \
    -c:v prores -profile:v 3 -pix_fmt yuv422p10 $resultfolder/$basefile

customlog "adapt timelapse video to audio track ($h:$m:$s)" 
# adapt timelapse video to audio track
ffmpeg -i $resultfolder/$basefile -filter:v "setpts=($vduration/$nbimages)*N/TB" -r $nbimages/$vduration -an $vfile


customlog "merge timelapse and freezeframe to $temptimedfile" 
# merge timelapse and freezeframe
mergelist="
file '$basefolder/$vfile'
file '$basefolder/$outrofile'
"
ffmpeg -f concat -safe 0  -i <(echo "$mergelist") -vcodec copy -acodec copy $temptimedfile


customlog "merge audio and video to $resultfolder/$outputfile" 
# merge audio and video
ffmpeg -i $temptimedfile -i $music -c copy -map 0:v:0 -map 1:a:0 -shortest $resultfolder/$outputfile

customlog "create mp4 video from result to $resultfolder/$finaltimelapse" 
# convert final video to mp4
ffmpeg -i $resultfolder/$outputfile -c:v libx264 -c:a aac -vf format=yuv420p -movflags +faststart $resultfolder/$finaltimelapse