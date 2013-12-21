Youtube Get

A simple low argument bash wrapper and download queue for youtube-dl

The basic idea is that we pre-configure the most used options to simplify repetitive use. This could be accomplished with a tiny script. yget started this way but evolved to maintain a list of videos to download sequentially, allowing for the seperation between video discovery and later viewing. Perhaps more comfortably via XBMC and a TV ;-)

Prerequisites:

    YouTube-DL https://github.com/rg3/youtube-dl
    Python
    Some flavor of *nix. (Fedora keeps youtube-dl updated regularly)

Important setup notes:

    run yget once to crerate the working directory
    copy [yget directory]/templates/yget.conf file to $HOME/.local/share/yget/yget.conf
    edit yget.conf to work with your directory structure

    DOWN_STREAM_RATE - use to cap the bandwidth youtube dl will use
    OUTPUT_PATH      - where your videos will be saved
    NOTIFY_ICON      - the icon to use for desktop notifications
    DATABASE         - file where yget stores temporary data eg /tmp/somefile


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

