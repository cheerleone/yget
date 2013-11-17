#!/bin/bash

:<<BLOCK_COMMENT

  Youtube-Get v3.see.below

  License: GPL-V2.0

  Copyright 2012 RWM.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

Update to 3.1.6.beta by OblongOrange 2013/15/11
  Now adds the video quality value to the end of the downloaded video filename (see old Known Limitation (2.1) in docs/knownbugs.txt)
Update to 3.1.7.beta by OblongOrange 2013/15/11
  Check_If_Running function updated to check for the existence of the youtube-dl Process itself, and no longer finds all lines containing 'youtube-dl'

BLOCK_COMMENT

#-------------------------------------------------------------------------------

  # version

VERSION="3.1.8.beta";                          # major.minor.point.stage

  # user settings

DOWN_STREAM_RATE="5600K";                      # ~75% of connection speed is good
OUTPUT_PATH="$HOME/Videos";                    # where to put downloaded videos
NOTIFY_ICON="/usr/share/icons/Faenza/apps/scalable/youtube.svg"; # url to icon used in GUI notifications
DATABASEPATH=$HOME/.local/share/yget;
DATABASE="$DATABASEPATH/yg.db";                # where to place working video queue

  # dev options

DEBUG="Y";                                     # output debug information if "Y"

  # global variables /vomit

ALREADY_RUNNING="FALSE";                       # ensure only 1 download per system
ARGUMENT="$1";                                 # user function select / script clarity
REQUESTED_FORMAT=;                             # 1080p, 720p etc supplied to $1 as h (high), m (medium), l (low)
VIDEO_TITLE=;                                  # title
VIDEO_URL="$2";                                # URL to video
URL_OK="FALSE";                                # return from youtube-dl initial call (ret. TRUE if URL was good)
PREFIX="1006665b__";                           # basic record id. / good for record grep / future asv header
RECORDS_IN_DB=;                                # cosmetic output and loop end determination
ACTUAL_FORMAT=;                                # cosmetic user notification of the video format thtat will be downloaded
FORMAT_STRING=;                                # cosmetic user output
DL_ERRORS=0;                                   # counter for determining how many times youtube-dl exited abnormally
MAX_DL_ERRORS=8;                               # .. abnormal exit cap
ERROR_TIME=24;				                         # number of seconds to wait after an error.

#-------------------------------------------------------------------------------

  # functions

function Convert_Quality {
  case "$ARGUMENT" in
    h)  REQUESTED_FORMAT="46"; ;;
    m)  REQUESTED_FORMAT="45"; ;;
    l)  REQUESTED_FORMAT="44"; ;;
  esac
}

function Convert_Format_To_String {            # youtube only, rest fall into the 'unknown' category, but should work
  FORMAT_STRING="$ACTUAL_FORMAT";
}

function Output_Options {
  echo "";
  echo "Youtube Get";
  echo "";
  echo "Options:";
  echo "  Argument one      : Quality Settings";
  echo "    add";
  echo "      h             : high quality   (1080p)";
  echo "      m             : medium quality (720p)";
  echo "      l             : low quality    (480p)";
  echo "";
  echo "  Argument two";
  echo "    URL             : URL of Video";
  echo "";
  echo "  Argument one      : Options";
  echo "    s               : Start download";
  echo "    L               : List titles in queue";
  echo "    Ll              : List titles in queue + loop until done";
  echo "    d               : Delete first title in queue";
  echo "    D               : Delete database / queue";
  echo "    p               : Push first record to last - if 2+";
  echo "    v               : Version";
  echo "";
  echo "  Examples";
  echo "    yg h https://youtube.com/somevideo";
  echo "       -- add high quality 1080p videoto queue";
  echo "    yg L";
  echo "       -- list queued videos in database";
  echo "    yg s";
  echo "       -- start download"
}

function Show_Version {
  echo $VERSION;
}

function Query_URL {
  local QUERY_RETURN=;
  Convert_Quality;
  echo; echo "Querying Video..";
  QUERY_RETURN=$( youtube-dl -e --get-title --get-format --prefer-free-formats --max-quality $REQUESTED_FORMAT $VIDEO_URL );
  if [ "$?" = "0" ]; then                                     # if youtube-dl url query succeeded ..
    URL_OK="TRUE";                                            # .. set success state
    VIDEO_TITLE=$( echo "$QUERY_RETURN" | sed -n -e "1"p );   # .. title = 1st line from query
    ACTUAL_FORMAT=$( echo "$QUERY_RETURN" | sed -n -e "2"p ); # .. a.fmt = 2nd line. junk if not youtube, don't use for reqest.
  else                                                        # if youtube-dl url query failed ..
    URL_OK="FALSE";                                           # .. set fail state
  fi
}

function Delete_DB {
  rm $DATABASE > /dev/null;
}

function Check_If_Running {
  ps acx | grep youtube-dl > /dev/null;                   # get process-only list with any youtube-dl entries
  if [ "$?" = "0" ]; then                                 # .. 0 if running
    ALREADY_RUNNING="TRUE";                               # yes? return true
  else
    ALREADY_RUNNING="FALSE";                              # no? return false
  fi  
}

function Add_Record {
#  Convert_Quality;      
  Query_URL;
  if [ "$URL_OK" = "TRUE" ]; then
    echo "Adding: $VIDEO_TITLE";
    echo "$PREFIX@$REQUESTED_FORMAT@$VIDEO_URL@$VIDEO_TITLE@$ACTUAL_FORMAT" >> $DATABASE;
    echo "Done.";
  else
    echo "Invalid URL, check arguments with -h";
  fi  
}

function Add_Record_Internal {
    echo "$PREFIX@$REQUESTED_FORMAT@$VIDEO_URL@$VIDEO_TITLE@$ACTUAL_FORMAT" >> $DATABASE;
}

function Count_Records {
  if [ -f $DATABASE ]; then                                    # if DB file exists
    RECORDS_IN_DB=$( grep -cw "$PREFIX" "$DATABASE" );         # .. count number of records left in DB
  else
    RECORDS_IN_DB="0";                                         # .. else set to 0 records
  fi
}

function List_Titles_In_DB {
  local RECORD_INDEX=1;                                        # points to current record being read / output
  Count_Records;                                               # determine how many videos queued in DB
  if [ $RECORDS_IN_DB -ne 0 ]; then                            #
#    echo "Videos in queue..";                                  #
    while [ $RECORD_INDEX -le $RECORDS_IN_DB ]; do             #
      VIDEO_TITLE=$( sed -n -e "$RECORD_INDEX"p $DATABASE | cut -d@ -f4 );  # extract title from 4th field in line n of DB
      echo " $RECORD_INDEX, $VIDEO_TITLE";                     #
      RECORD_INDEX=$( expr $RECORD_INDEX + 1 );                #
    done                                                       #
  else                                                         #
    echo "No videos in queue.";                                #
  fi                                                           #
}

function List_Titles_In_DB_Loop {
  clear;
  while [ -f $DATABASE ]; do
    List_Titles_In_DB;
    sleep 8;
    clear;
  done  
}

function Display_Header {
  Convert_Format_To_String;
  echo;
  echo "D/S Rate          : $DOWN_STREAM_RATE";
  echo "Downloading       : $VIDEO_TITLE";  
  if [ $DEBUG = "Y" ]; then
    echo "URL               : $VIDEO_URL";
  fi
  case "$REQUESTED_FORMAT" in
    46) echo "Requested Format  : 1080p format $REQUESTED_FORMAT - WebM"; ;;
    45) echo "Requested Format  : 720p format $REQUESTED_FORMAT - WebM"; ;;
    44) echo "Requested Format  : 480p format $REQUESTED_FORMAT - WebM"; ;;
  esac
  echo "Actual Format     : $FORMAT_STRING";
  echo "D/L Remaining     : $RECORDS_IN_DB";
  if [ $DL_ERRORS -ne 0 ]; then
    echo "D/L Errors        : $DL_ERRORS (max: $MAX_DL_ERRORS)";
  fi
  echo;
}

function Read_First_Record {                               # read field 2-5 from 1st record into variables.
  ACTUAL_FORMAT=$( head -1 "$DATABASE" | cut -d@ -f5 );    # extract actual format - 5th field
  VIDEO_TITLE=$( head -1 "$DATABASE" | cut -d@ -f4 );      # extract itle - 4th field
  VIDEO_URL=$( head -1 "$DATABASE" | cut -d@ -f3 );        # extract url - 3rd field
  REQUESTED_FORMAT=$( head -1 "$DATABASE" | cut -d@ -f2 ); # extract requested format - 2nd field
}

function Delete_First_Record {
  sed -i '1d' "$DATABASE";                     # delete first entry line in Database
}

function Delete_First_Record_Option {
  if [ -f $DATABASE ]; then                    # if database exists..
    Count_Records;
    if [ "$RECORDS_IN_DB" -ge 1 ]; then        # if one or more records in DB..
      Delete_First_Record;                     # .. delete first entry line in database
      echo "deleted 1 record";
    fi
    if [ "$RECORDS_IN_DB" -le 1 ]; then        # if one or fewer records in DB..
      Delete_DB;                               # .. delete the database
      echo "No more records, Database deleted.";
    fi
  else
    echo "Database file not found!";
  fi
}

function Send_GUI_Notification {
  notify-send --hint=int:transient:1 -i $NOTIFY_ICON "$VIDEO_TITLE ** downloaded";  
  echo -en "\007";
}

function Push_First_Record_To_Last {
  # move top record to bottom if 2 or more records exist
  # used when error detected in one video, so that others will be downloaded - if net connection available
  Check_If_Running;                            # check if already downloading a video..
  if [ "$ALREADY_RUNNING" = "FALSE" ]; then    # ..if not running, continue
    Count_Records;
    if [ $RECORDS_IN_DB -ge "2" ]; then
      echo "Moving first record to end..";
      Read_First_Record;
      Add_Record_Internal;
      Delete_First_Record;
      echo "done."
    else
      echo "There must be 2 or more records to move the record.";
    fi
  else
    echo "Can not push record while download is in progress.";
  fi
}

function Push_Last_Record_To_Top {
  #cheesyest method of accomplishing this ever, note to self, learn to program!
  Count_Records;
  if [ $RECORDS_IN_DB -ge "2" ]; then
    echo "Moving record..";
    for (( i=1; i<$RECORDS_IN_DB; i++ )) do
      Push_First_Record_To_Last;
    done 
    List_Titles_In_DB;
  else
    echo "There must be 2 or more records to move the record.";
  fi
}

function DL_Error_Trap {
  DL_ERRORS=$( expr $DL_ERRORS + 1 );
  if [ $DL_ERRORS -ge $MAX_DL_ERRORS ]; then
    echo "Too many errors reported from youtube-dl, exiting";
    exit 1
  else
    echo "sleeping for $ERROR_TIME seconds...";
    sleep $ERROR_TIME;                           # wait n seconds - helps the connection reset, possibly choosing a different yt. proxy
  fi
}

function Add_mq_and_Download {
  ARGUMENT="m";
  Add_Record;
  Download;
}

function CheckYGetDir {
  #check database directory exists, if not make it, if error exit script
  YGETDIR=$HOME/.local/share/yget
  if [ -d $YGETDIR ]; then
     echo -n
  else
    mkdir -p $YGETDIR
    if [ -d "$YGETDIR" ]; then
      echo -n
    else
      echo Error: Could not create $YGETDIR;
      exit 1;
    fi
  fi
}

# Creates the global variable $OUTPUT_TEMPLATE with the video title, id, and user selected video quality value. 
# $OUTPUT_TEMPLATE provides the template in the format for --output option discussed in the # manual entry for youtube-dl 
# Added 2013/11/15 by OblongOrange
# Updated to pull data from the format returned form the youtube-dl query ($ACTUAL_FORMAT), adding this where relevant.
function Create_Output_Template {
  local FMT=;
  FMT=$( echo $ACTUAL_FORMAT | awk {' print $3 '} | cut -dx -f1) # eg return 720 from a string like "22 - 720x1280"
  case "$FMT" in
    "360"  ) FMT="-"$FMT"p" ; ;;               # add "p" to $FTM if the format fits any of the values below
    "480"  ) FMT="-"$FMT"p" ; ;;
    "720"  ) FMT="-"$FMT"p" ; ;;
    "1080" ) FMT="-"$FMT"p" ; ;;
    *      ) FMT="" ; ;;                       # otherwise set $FMT to an empty string.    
  esac
  OUTPUT_TEMPLATE="%(title)s-%(id)s$FMT";
}

function Download {
  Check_If_Running;                            # check if already downloading a video..
  if [ "$ALREADY_RUNNING" = "FALSE" ]; then    # ..if not running, continue
    Count_Records;                             # check number of videos remaining in list
    if [ "$RECORDS_IN_DB" != "0" ]; then       # if one or more videos to download..
      until [ "$RECORDS_IN_DB" = "0" ]; do     # ..loop until there are no more left to download
        if [ "$DEBUG" = "Y" ]; then
          List_Titles_In_DB;
        fi
        Read_First_Record;                     # populate nasty globals :( from first (top-most) record
        Display_Header;                        # output info from video record
        Create_Output_Template;                # create the OUTPUT_TEMPLATE for filename (adds quality value to filename)
        youtube-dl --output $OUTPUT_TEMPLATE -r $DOWN_STREAM_RATE --prefer-free-formats --max-quality $REQUESTED_FORMAT "$VIDEO_URL"; # da shiz.
        if [ "$?" = "0" ]; then                # if youtube-dl returned download success (0) then ..
          Send_GUI_Notification;               # ..send GUI notification
          Delete_First_Record;                 # ..delete record at top of list
          DL_ERRORS=0;                         # reset error state for next video
        else
          DL_Error_Trap;                       # catch youtube-dl errors to prevent infinite loops, or trap control+c
        fi                                     # end if youtube-dl success
        Count_Records;                         # re-check # remaining videos (could have been ++ in another instance)
      done                                     # end until-do; no more videos to download
      echo; echo "All videos have been downloaded"; echo;
      Delete_DB;                               # delete temporary working database file    
    else                                       # if no videos remaining..
      echo "No Videos to Download";            # .. display msg. - probably called with 's', without videos in list >.>
    fi                                         # end if - videos remaining
  else                                         # else if: youtube-dl is already running..
    echo "Video will download in primary process, exiting."; # output apropriate message
  fi                                           # end if - already running 
}

#-------------------------------------------------------------------------------

function Main {
  CheckYGetDir;
  cd $OUTPUT_PATH;
  case "$ARGUMENT" in                          # menu: compare commandline input to menu options
    [hml]) Add_Record; ;;                      # if user option = l/m/h .. add url
    ms) Add_mq_and_Download; ;;
    s) Download; ;;                            # start download - e.g. continue after power cycle etc.
    L) List_Titles_In_DB;  ;;                  # Output queued video titles in database
    Ll)List_Titles_In_DB_Loop;  ;;             # Output queued video titles in database + loop
    d) Delete_First_Record_Option; ;;
    D) Delete_DB; ;;                           # 
    v) Show_Version; ;;                        # too confusing to write a comment for
    p) Push_First_Record_To_Last; ;;           #
    t) Push_Last_Record_To_Top; ;;
    *) Output_Options; ;;
  esac
  echo;
}

#-------------------------------------------------------------------------------

  Main;
  exit 0;

  # The End.

