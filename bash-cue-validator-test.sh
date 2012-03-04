#!/bin/bash

com=" CATALOG CDTEXTFILE FILE FLAGS INDEX ISRC PERFORMER POSTGAP PREGAP REM SONGWRITER TITLE TRACK "

if [ "$(echo " WAVE MP3 AIFF " | grep -o " $(grep -m1 FILE "$1" | sed -n 's/.* //p' | tr -d '\f\r') ")" ]
then
#~  General parsing
    header=`head -c3 "$1" | xxd -p`
    [ $(echo $header | grep -o "efbbbf") ] && echo "UTF-8 BOM detected"
    [ $(echo "$header `echo $header | rev`" | grep -o "feff") ] && echo "UTF-16 BOM detected"

    [ "$(head -n1 "$1" | rev | cut -c1 | xxd -p)" = "0d0a" ] ||\
            echo "Non-CRLF line ending"

    [ "$(grep -m1 INDEX "$1" | grep -o '..:..:..')" == "00:00:00" ] ||\
        echo "Wrong start index"

    tracks=$(grep -o "TRACK [0-9]\+" "$1" | cut -d" " -f2)
    [ $((`echo "$tracks" | head -n1`)) -eq 1 ] || echo "First track not 01"
    [ $((10#`echo "$tracks" | tail -n1`)) -gt 99 ] && echo "Tracks out of range"
    [ "$(echo "$tracks" | sort -uc 2>&1)" ] && echo "Tracks not in sequence"

#~  Multiline parsing
    IFS=$'\n'
    for p in $(grep -o "TRACK\|INDEX 01" "$1" | tr "\n" " " | sed 's/INDEX 01 /&\n/g')
        do [ "$p" = "TRACK INDEX 01 " ] || echo "Track w/o matching index"
        done
    for p in $(grep -o "TRACK\|PREGAP\|INDEX 00" "$1" | tr "\n" " " | sed 's/TRACK/\n&/g')
        do [ "$p" = "TRACK PREGAP INDEX 00 " ] && echo "PREGAP and INDEX 00 on same track"
        done
    for p in $(grep -o "TRACK\|INDEX .." "$1" | tr "\n" " " | sed 's/.\?TRACK /\n/g;s/INDEX //g;s/ $//')
        do [ "$(echo "$p" | tr " " "\n" | sort -uc 2>&1)" ] && echo "Indexes not in sequence"
        done
    unset IFS

#~  Per line parsing
    while read line
    do
        l=$((l+1))
        if [ $l != 1 ]; then
            [ "$(echo "$com" | grep -o " `echo "$line" | grep -o '^[A-Z]\+'` ")" ] ||\
                echo "[$l] Unknown command"
        fi

        [ $((`echo "$line" | sed 's/[^"]//g' | tr -d '\n' | wc -m` % 2)) -eq 0 ] ||\
            echo "[$l] Non-matching quote"

        fn=$(echo $line | grep -o 'FILE.*' | cut -d\" -f2)
        if [ "$fn" ]; then [ -f "$fn" ] || echo "[$l] Invalid referenced file"; fi

        [ $((10#`echo "$line" | grep -o "..:..:.." | cut -d: -f2`)) -gt 59 ] &&\
            echo "[$l] Wrong time format [..:XX:..]"
        [ $((10#`echo "$line" | grep -o "..:..:.." | cut -d: -f3`)) -gt 74 ] &&\
            echo "[$l] Wrong time format [..:..:XX]"

        [ "$(echo "$line" | grep -o '^FILE')" ] && [ "$IDX" == "INDEX 00" ] &&\
            echo "[$l] Non-compliant cue-sheet"
        IDX=$(echo $line | grep -o "INDEX ..")
    done < "$1"

else

    [ -f "$(grep -m1 FILE "$1" | cut -d\" -f2)" ] || echo "Invalid referenced file"

fi
