Two bash scripts are present:

- *bash-cue-validator-test*

This will output possible problems when called from terminal:

```
$ bash-cue-validator-test my-cue-sheet.cue
```

- *bash-cue-validator-thumb*

This is intended to be used as Nautilus thumbnail handler.

Here is how it can be set from terminal (taking care of ** path-to **):

```
$ gconftool-2 -s "/desktop/gnome/thumbnailers/application@x-cue/command" -t string "/ ** path-to ** /bash-cue-validator-thumb.sh %i %o %s"
$ gconftool-2 -s "/desktop/gnome/thumbnailers/application@x-cue/enable" -t boolean 'true'
```

After-which it should show annotated thumbs for cue sheets.

Sample images are provided, which are taken from Faenza icon set. I couldn't find a way to use stock icons reliably from bash, so they are needed in script folder. Can be easily replaced with different images under same name.

**Example:**

This cue sheet has invalid referenced file inside (IREF annotated):

![screen-shot](http://i.imgur.com/Uxsur.png "Cue sheet with error")


After correcting referenced filepath, warning is shown about non-compliant cue sheet and presence of UTF-8 BOM header:

![screen-shot](http://i.imgur.com/d9df7.png "Cue sheet with warning")


Now, this is valid cue sheet (according to the script ;) )

![screen-shot](http://i.imgur.com/3amAt.png "Correct cue sheet")
