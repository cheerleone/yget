Youtube Get

A simple low argument bash wrapper and download queue for youtube-dl

The basic idea is that we pre-configure the most used options to simplify repetitive use. This could be accomplished with a tiny script. yget started this way but evolved to maintain a list of videos to download sequentially, allowing for the seperation between video discovery and later viewing. Perhaps more comfortably via XBMC and a TV ;-)

Prerequisites:

    YouTube-DL https://github.com/rg3/youtube-dl
    Python
    Some flavor of *nix. (Fedora keeps youtube-dl updated regularly)

Important setup notes: Edit supplied yget.conf to configure user environment settings:

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

Experimental Pro-Tip:

     For people running file servers and multiple workstations: yget can run in polling mode (option "P"). Using a command like screen you could run yget as daemon.
 
     1) Configure the workstation yget.config to point the $DATABASE variable to location on the fileserver. 
     2) Configure the yget server running in screen in polling mode to access the same database file
     3) Set the server's video output folder to the fileserver's preferred video directory.

     In this mode you could add many videos locally on your workstation(s) while the server downloads them sequentially to your favorite network location. Alternatively You could also set a cron job to download the videos overnight such that the bandwidth isn't hogged during your active hours. The net benefit is then having access to your downloaded videos to watch from any networked location, and the ability to shutdown any workstations.

-------
doc.1.5

