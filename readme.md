Youtube Get

A simple low argument bash front end for youtube-dl...

at least once it’s configured for your environment.

Important setup notes: Edit script to configure user environment settings:

DOWN_STREAM_RATE - use to cap the bandwidth youtube dl will use
OUTPUT_PATH - where your videos will be saved
NOTIFY_ICON - the icon to use for desktop notifications.
DATABASE - file where yget stores temporary data eg /tmp/somefile

Bash and aliases
I strongly recommend an alias to your ~/.bashrc file such as:

alias yg='$HOME/devel/yget/yget-3-1-4'

Be sure to set the alias to the current version, close and re-open your terminal then run yget simply by typing yg

For help type:

 yg -h | more

Lastly, if your youtube links contain the “&” character, be sure to encapsulate the url in quotes, otherwise the & will fork back to the command line, but continue to output script messages.

    yg m “https://www.youtube.com/v/_-GYgAxsbPs?version=3&f=user_uploads&app=youtube_gdata”



