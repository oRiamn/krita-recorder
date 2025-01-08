#!/bin/bash
basefolder="$PWD"
localconfigfolder="$basefolder/.config"
logfilename="$localconfigfolder/debug.log"
signaturefile=$(mktemp)
md5filename="$localconfigfolder/.md5base"

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

convertsecs() {
    h=$(bc <<< "${1}/3600")
    m=$(bc <<< "(${1}%3600)/60")
    s=$(bc <<< "${1}%60")
    printf "%02d:%02d:%05.2f\n" $h $m $s
}

resultfolder=$(getConfigValue targetpath "$basefolder/result")
resizevalue=$(getConfigValue resize 1000)
recordtilt=$(getConfigValue recordtilt 10)
timestampcolor=$(getConfigValue timestampcolor "white")
i="  "

touch $logfilename
touch $md5filename
mkdir -p $resultfolder

customlog "starting from $PWD"
customlog "$i localconfigfolder $localconfigfolder"
customlog "$i signature base file $signaturefile"
customlog "$i md5 base file $md5filename"
customlog "$i resize $resizevalue"
customlog "$i timestampcolor $timestampcolor"
customlog "$i recordtilt $recordtilt"

for filename in *.png; do
    md5=($(md5sum $filename))
    if grep -Fxq "$md5" $md5filename
    then
         customlog "$i $filename exist in md5 base no action needed ($md5)"
    else
        signature=$(identify -verbose $filename | grep signature | cut -f2 -d":" | cut -f2 -d" ")

        customlog "$i $filename $md5 $signature"

        if grep -Fxq "$signature" $signaturefile
        then
            customlog "$i $filename exist in signature base no action needed ($signature)"
        else
            customlog "$i move $filename in $resultfolder"
            
            framenum=$(echo $filename | cut -d '.' -f1 | bc)
            seconds=$(((framenum+0)*recordtilt))
            timestamp=$(convertsecs $seconds)
            
            convert -font helvetica -fill $timestampcolor -pointsize 70 -gravity southeast -draw "text 40,20 '$timestamp'" $filename -resize $resizevalue "$resultfolder/$filename"
        fi
        echo "$signature" >> $signaturefile
        echo "$md5" >> $md5filename
    fi
done

lastimage=$(find *.png | tail -n 1)

temptarfile="$(mktemp -d)/$(date +%F_%T).tar.gz"
tar -zcvf $temptarfile ../$(basename $PWD)
mv $temptarfile $resultfolder
find *.png | grep -v "$lastimage" | xargs -d '\n' rm -f --
