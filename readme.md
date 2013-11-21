Youtube Get

A simple low argument bash wrapper and download queue for youtube-dl

The basic idea is that we pre-configure the (my!) most used options to simplify use. This could be accomplished with a tiny script. yget started this way but evolved to maintain a list of many potential videos to download sequentially, allowing for the seperation between video discovery and watching later, perhaps more comfortably via XBMC and a TV ;-)

Prerequisites:

    YouTube-DL https://github.com/rg3/youtube-dl
    Python
    Some flavor of *nix. (Fedora keeps youtube-dl updated regularly)

Important setup notes: Edit script to configure user environment settings:

    DOWN_STREAM_RATE - use to cap the bandwidth youtube dl will use
    OUTPUT_PATH      - where your videos will be saved
    NOTIFY_ICON      - the icon to use for desktop notifications
    DATABASE         - file where yget stores temporary data eg /tmp/somefile

These Settings should be moved to a config file in a future update.

Bash and aliases, I strongly recommend adding an alias to your ~/.bashrc file such as:

    alias yg='$HOME/scripts/yget.sh'

reload your .bashrc file with:

    source ~/.bashrc
     
For help type:

    yg -h | more

Lastly, if your youtube links contain the “&” character, be sure to encapsulate the url in quotes, otherwise the & will fork back to the command line, but continue to output script messages.

    yg m “https://www.youtube.com/v/_-GYgAxsbPs?version=3&f=user_uploads&app=youtube_gdata”

-------
doc.1.4

