#!/bin/bash

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

COM=" CATALOG CDTEXTFILE FILE FLAGS INDEX ISRC PERFORMER POSTGAP PREGAP REM SONGWRITER TITLE TRACK "
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
            [ "$(echo "$COM" | grep -o " `echo "$line" | grep -o '^[A-Z]\+'` ")" ] || err "UCOM"
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

    [ -f "${1%/*}/$(echo "$DAT" | grep -m1 FILE | cut -d\" -f2)" ] || err "IREF"

fi

B64="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"

dump() { echo $B64 | base64 -d | xz -dc | sed "40 s/e6e6e6/$4/" |\
	    convert -background none -density 300 - -resize x$3 -fill $5 -font DejaVu-Sans-Condensed -pointsize 3 \
	    -gravity SouthWest -undercolor $6 -annotate 0+0 "$1" png:"$2"; }

if [ "$ERR" ]; then dump "$ERR" "$2" $3 d40000 yellow black
else [ "$WARN" ] && dump "$WARN" "$2" $3 ff9000 black white ||\
    echo $B64 | base64 -d | xz -dc | sed '40 s/e6e6e6/8fc543/' |\
	convert -background none -density 300 - -resize x$3 png:"$2"
fi