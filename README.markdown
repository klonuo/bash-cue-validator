***

###Usage:

- **bash-cue-validator-test.sh**

This will output possible problems when called from terminal:

```
$ ./bash-cue-validator-test.sh my-cue-sheet.cue
```

- **bash-cue-validator-thumbs.sh**

This is intended to be used as Nautilus thumbnail handler.

Here is how it can be set from terminal (change ** path-to ** accordingly):

```
$ gconftool-2 -s "/desktop/gnome/thumbnailers/application@x-cue/command" -t string "/ ** path-to ** /bash-cue-validator-thumbs.sh %i %o %s"
$ gconftool-2 -s "/desktop/gnome/thumbnailers/application@x-cue/enable" -t boolean 'true'
```

After-which it should show annotated thumbs for cue sheets (don't forget `chmod +x`)

***

###Example:

This cue sheet has invalid referenced file inside (IREF annotated):

![screen-shot](http://i.imgur.com/Uxsur.png "Cue sheet with error")


After correcting referenced filepath, warning is shown about non-compliant cue sheet and presence of UTF-8 BOM header:

![screen-shot](http://i.imgur.com/d9df7.png "Cue sheet with warning")


Now, this is valid cue sheet ( according the script ;) )

![screen-shot](http://i.imgur.com/uHwkd.png "Correct cue sheet")

***

###Changes:

bash-cue-validator-thumbs.sh
0.2

 - SVGs are removed and instead single SVG is xz-ed and base64-ed inside script, then sed-ed to give particular color mask
 - changed output to tranparent with greater quality