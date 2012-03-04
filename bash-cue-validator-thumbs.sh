#!/bin/bash

com=" CATALOG CDTEXTFILE FILE FLAGS INDEX ISRC PERFORMER POSTGAP PREGAP REM SONGWRITER TITLE TRACK "

#~      Warnings:
#~ BOM8:   UTF-8 BOM detected
#~ BO16:   UTF-16 BOM detected
#~ CRLF:   Non-CRLF line ending
#~ IDXS:   Wrong start index
#~ NONC:   Non-compliant cue-sheet
#~
#~      Errors:
#~ TRKS:   First track not 01
#~ TRKX:   Tracks out of range
#~ TRKQ:   Tracks not in sequence
#~ TRKI:   Track w/o matching index
#~ GAP0:   PREGAP and INDEX 00 on same track
#~ IDXQ:   Indexes not in sequence
#~ UCOM:   Unknown command
#~ QUOT:   Non-matching quote
#~ IREF:   Invalid referenced file
#~ TSEC:   Wrong time format [..:XX:..]
#~ TFRM:   Wrong time format [..:..:XX]

com=" CATALOG CDTEXTFILE FILE FLAGS INDEX ISRC PERFORMER POSTGAP PREGAP REM SONGWRITER TITLE TRACK "
DAT=$(cat "$1")

err() { [[ "$ERR" == *" $1"* ]] || ERR="$ERR $1"; }

warn() { [[ "$WARN" == *" $1"* ]] || WARN="$WARN $1"; }

if [ "$(echo " WAVE MP3 AIFF " | grep -o " $(echo "$DAT" | grep -m1 FILE | sed -n 's/.* //p' | tr -d '\f\r') ")" ]
then
#~  General parsing
    header=`echo "$DAT" | head -c3 | xxd -p`
    [ $(echo $header | grep -o "efbbbf") ] && warn "BOM8"
    [ $(echo "$header `echo $header | rev`" | grep -o "feff") ] && warn "BO16"

    [ "$(echo "$DAT" | head -n1 | rev | cut -c1 | xxd -p)" = "0d0a" ] || warn "CRLF"
    [ "$(echo "$DAT" | grep -m1 INDEX | grep -o '..:..:..')" == "00:00:00" ] || warn "IDXS"

    tracks=$(echo "$DAT" | grep -o "TRACK [0-9]\+" | cut -d" " -f2)
    [ $((`echo "$tracks" | head -n1`)) -eq 1 ] || err "TRKS"
    [ $((10#`echo "$tracks" | tail -n1`)) -gt 99 ] && err "TRKX"
    [ "$(echo "$tracks" | sort -uc 2>&1)" ] && err "TRKQ"

#~  Multiline parsing
    IFS=$'\n'
    for p in $(echo "$DAT" | grep -o "TRACK\|INDEX 01" | tr "\n" " " | sed 's/INDEX 01 /&\n/g')
        do [ "$p" = "TRACK INDEX 01 " ] || err "TRKI"; done
    for p in $(echo "$DAT" | grep -o "TRACK\|PREGAP\|INDEX 00" | tr "\n" " " | sed 's/TRACK/\n&/g')
        do [ "$p" = "TRACK PREGAP INDEX 00 " ] && err "GAP0"; done
    for p in $(echo "$DAT" | grep -o "TRACK\|INDEX .." | tr "\n" " " | sed 's/.\?TRACK /\n/g;s/INDEX //g;s/ $//')
        do [ "$(echo "$p" | tr " " "\n" | sort -uc 2>&1)" ] && err "IDXQ"; done
    unset IFS


#~  Per line parsing
    while read line
    do
        if [ "$WARN" != *" BO"* -a "$IDX" != "" ]; then
            [ "$(echo "$com" | grep -o " `echo "$line" | grep -o '^[A-Z]\+'` ")" ] || err "UCOM"
        fi

        [ $((`echo "$line" | sed 's/[^"]//g' | tr -d '\n' | wc -m` % 2)) -eq 0 ] || err "QUOT"

        fn=$(echo $line | grep -o 'FILE.*' | cut -d\" -f2)
        if [ "$fn" ]; then [ -f "${1%/*}/$fn" ] || err "IREF"; fi

        [ $((10#`echo "$line" | grep -o "..:..:.." | cut -d: -f2`)) -gt 59 ] && err "TSEC"
        [ $((10#`echo "$line" | grep -o "..:..:.." | cut -d: -f3`)) -gt 74 ] && err "TFRM"

        [ "$(echo "$line" | grep -o '^FILE')" ] && [ "$IDX" == "INDEX 00" ] && warn "NONC"
        IDX=$(echo $line | grep -o "INDEX ..")
    done <<< "$DAT"

else

    [ -f "$(echo "$DAT" | grep -m1 FILE | cut -d\" -f2)" ] || echo "Invalid referenced file"

fi

if [ "$ERR" ]; then
convert "$( dirname "${BASH_SOURCE[0]}" )/error.svg" -resize x$3 -fill yellow -font DejaVu-Sans-Condensed -pointsize 11 \
    -gravity SouthWest -undercolor black -annotate 0+10 "$ERR" png:"$2"
else [ "$WARN" ] &&\
convert "$( dirname "${BASH_SOURCE[0]}" )/warn.svg" -resize x$3 -fill black -font DejaVu-Sans-Condensed -pointsize 11 \
    -gravity SouthWest -undercolor white -annotate 0+10 "$WARN" png:"$2" ||\
convert "$( dirname "${BASH_SOURCE[0]}" )/info.svg" -resize x$3 png:"$2"
fi
