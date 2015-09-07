#!/bin/bash

:<<BLOCK_COMMENT

  Youtube-Get v3.see.below

  License: GPL-V2.0

  Copyright 2012 RWM.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

BLOCK_COMMENT

#-------------------------------------------------------------------------------

  # version

VERSION="3.2.11.alpha";                        # major.minor.point.stage

  # Configuration File
  
CONFIG_FILE=$HOME/.local/share/yget/yget.conf  # configuration file to use

  # global variables from config file

DOWN_STREAM_RATE="";                           # ~75% of connection speed is good      -- pulled from config file
DATABASEPATH="";                               # yget working directory                -- pulled from config file
DATABASE="";                                   # database filename                     -- pulled from config file
OUTPUT_PATH="";                                # where to store downloaded videos      -- pulled from config file
NOTIFY_ICON="";                                # url to icon used in GUI notifications -- pulled from config file
DESKTOP_NOTIFICATION="";                       # YES/NO - bell disregards this option  -- pulled from config file 
DEBUG="";                                      # output debug information if "Y"       -- pulled from config file

  # global variables

ALREADY_RUNNING="FALSE";                       # ensure only 1 download per system
ARGUMENT="$1";                                 # user function select / script clarity
REQ_FMT2=;                                     # TEST_VAR: converted video frame height, 480, 720, 1080 from l, m h.
VIDEO_TITLE=;                                  # title
VIDEO_URL="$2";                                # URL to video
URL_OK="FALSE";                                # return from youtube-dl initial call (ret. TRUE if URL was good)
RETURNED_FORMAT=;                              # hopefully video frame height, used for output formatting and output file name
PREFIX="__100__";                              # basic record id. / good for record grep / future asv header
RECORDS_IN_DB=;                                # cosmetic output and loop end determination
DL_ERRORS=0;                                   # counter for determining how many times youtube-dl exited abnormally
MAX_DL_ERRORS=8;                               # .. abnormal exit cap
ERROR_TIME=16;                                 # number of seconds to wait after an error.


#-------------------------------------------------------------------------------

  # functions

function Convert_Quality {
  case "$ARGUMENT" in
    h) REQ_FMT2="1080"; ;;
    m) REQ_FMT2="720"; ;;
    l) REQ_FMT2="480"; ;;
  esac
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
  echo "       -- add high quality 1080p video to queue";
  echo "    yg L";
  echo "       -- list queued videos in database";
  echo "    yg s";
  echo "       -- start download"
}

function Show_Version {
  echo $VERSION;
}

function Expand_URL {                                         # if the usual URL variable passed on commandline is char "c" get URL from clipboard
  if [[ "$VIDEO_URL" = "c" ]]; then
    if [ -f "/usr/bin/xclip" ]; then                          # checked inside 1st if to make xclip a soft dependency, if 2nd argument is a full URL, this code will not execute
      VIDEO_URL=$(xclip -o);                                  # get url from clipboard
    else
      echo "xclip is required to expand a URL from the clipboard."
      exit 2
    fi
  fi    
}

function Query_URL {
  # test URL via youtube-dl, supply -e argument to simulate download, then use exit code to determine if the URL was ok.
  local QUERY_RETURN=;
  Convert_Quality;
  Expand_URL;
  echo; echo "Querying Video..";
  # QUERY_RETURN=$( youtube-dl -e --get-title --get-format --prefer-free-formats -f "bestvideo[height<=$REQ_FMT2]" $VIDEO_URL );
  QUERY_RETURN=$( youtube-dl -e --get-title --get-format --prefer-free-formats -f "[height<=$REQ_FMT2]" $VIDEO_URL );
  if [ "$?" = "0" ]; then                                     # if youtube-dl url query succeeded ..
    URL_OK="TRUE";                                            # .. set success state
    VIDEO_TITLE=$( echo "$QUERY_RETURN" | sed -n -e "1"p );   # .. title = 1st line from query
    RETURNED_FORMAT=$( echo "$QUERY_RETURN" | sed -n -e "2"p | cut -dx -f2 | cut -d" " -f1); # .. a.fmt = 2nd line. junk if not youtube, don't use for reqest.
  else                                                        # if youtube-dl url query failed ..
    URL_OK="FALSE";                                           # .. set fail state
  fi
  printf "DB:: qry.ret: $QUERY_RETURN\n";
  printf "DB:: ret.fmt: $RETURNED_FORMAT\n";
}

function Delete_DB {
  rm $DATABASE > /dev/null;
}

function Check_If_Running {
# ps acx | grep youtube-dl > /dev/null;
# acx does not work for scripts only executable files.
  ps ax | grep youtube-dl | grep -v grep | grep prefer-free > /dev/null;  #  reverted to original + extra test for running state parameter
  if [ "$?" = "0" ]; then                                 # .. 0 if running
    ALREADY_RUNNING="TRUE";                               # yes? return true
  else
    ALREADY_RUNNING="FALSE";                              # no? return false
  fi  
}

function Sanitize_Youtube_URLS {
  # many youtube URL's contain the ampersand (&) character which creates an issue passing the URL
  # to executables. This function detects if the url contains "youtube.com" as a string, if so, check
  # for and remove any ampersand and successive characters.
  # detect youtube
  echo $VIDEO_URL | grep youtube.com > /dev/null
  if [ "$?" = 0 ]; then                                   # exit code 0 = grep found youtube.com string in the URL
    # sanitize
    VIDEO_URL="${VIDEO_URL%%&*}"                          # strip ampersand and successive characters
  fi
}

function Add_Record {
  Sanitize_Youtube_URLS 
  Query_URL;
  if [ "$URL_OK" = "TRUE" ]; then
    echo "Adding: $VIDEO_TITLE";
    echo "$PREFIX@$REQ_FMT2@$VIDEO_URL@$VIDEO_TITLE@$RETURNED_FORMAT" >> $DATABASE;
    echo "Done.";
  else
    echo "Invalid URL, check arguments with -h";
  fi  
}

function Add_Record_Internal {
  echo "$PREFIX@$REQ_FMT2@$VIDEO_URL@$VIDEO_TITLE@$RETURNED_FORMAT" >> $DATABASE;
}

function Advance_Spinner {
  local CHARS="|/-\\";
  echo -n "${CHARS:$SPINDEX:1} ";
  echo -ne "$pc\033[0K\r"
  (( SPINDEX++ ));
  if [ $SPINDEX = 4 ]; then
    SPINDEX=0;
  fi   
}

function Poll_Clipboard {
  local CLIP_CURRENT="";
  local CLIP_CHECK="hsid8fyuib83riwk3urh";
  ARGUMENT="m";  
  Convert_Quality;  
  if [ -f "/usr/bin/xclip" ]; then
    echo foo | xclip -i
    echo "Polling for Youtube URL's on X Clipboard..   (CTRL+C to stop)"
    while [ 1 = 1 ]; do
      CLIP_CURRENT=$(xclip -o -quiet);                         # added -quiet to help suppress an xclip output bug
      echo $CLIP_CURRENT | grep "youtube.com/" > /dev/null
      if [[ "$?" = "0" ]]; then
        if [[ "$CLIP_CURRENT" != "$CLIP_CHECK" ]]; then          
          VIDEO_URL=$CLIP_CURRENT;
          Add_Record;
          CLIP_CHECK=$CLIP_CURRENT;
        fi
      fi
      sleep 1
      Advance_Spinner;
    done
  else
    echo "xclip is required to for clipboard functionality"
    exit 2
  fi
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
    while [ $RECORD_INDEX -le $RECORDS_IN_DB ]; do             #
      VIDEO_TITLE=$( sed -n -e "$RECORD_INDEX"p $DATABASE | cut -d@ -f4 );  # extract title from 4th field in line n of DB
      echo " $RECORD_INDEX $VIDEO_TITLE";                     #
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
  echo;
  echo "D/S Rate          : $DOWN_STREAM_RATE";
  echo "Downloading       : $VIDEO_TITLE";
  if [ "$DEBUG" = "Y" ]; then
    echo "URL               : $VIDEO_URL";
  fi
  case "$REQ_FMT2" in
    "1080") echo "Requested Format  : 1080p"; ;;
    "720") echo "Requested Format  : 720p"; ;;
    "480") echo "Requested Format  : 480p"; ;;
  esac  
  if [ ! "$RETURNED_FORMAT" = "" ]; then
    echo "Available Format  : $RETURNED_FORMAT""p";
  fi
  echo "D/L Remaining     : $RECORDS_IN_DB";
  if [ $DL_ERRORS -ne 0 ]; then
    echo "D/L Errors        : $DL_ERRORS (max: $MAX_DL_ERRORS)";
  fi
  echo;
}

function Read_First_Record {                               # read field 2-5 from 1st record into variables.
  VIDEO_TITLE=$( head -1 "$DATABASE" | cut -d@ -f4 );      # extract title - 4th field
  VIDEO_URL=$( head -1 "$DATABASE" | cut -d@ -f3 );        # extract url - 3rd field
  REQ_FMT2=$( head -1 "$DATABASE" | cut -d@ -f2 );         # extract requested format - 2nd field
  RETURNED_FORMAT=$( head -1 "$DATABASE" | cut -d@ -f5 );  # extract returned format - 5th field
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
  # set in config file, turn off for headless primarily server use - only prevents soft-errors where notifications can not be sent
  if [ "$DESKTOP_NOTIFICATION" = "YES" ]; then
    notify-send --hint=int:transient:1 -i $NOTIFY_ICON "$VIDEO_TITLE ** downloaded";
  fi
  # send bell character to cuttent terminal, results depend on shell / pc configuration. possible outcome of pc beep, or terminal flash
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

function Read_Config_File {
  echo "Reading config file..";
  if [ -f "$CONFIG_FILE" ]; then
    DOWN_STREAM_RATE=$( cat $CONFIG_FILE | grep _DOWN_STREAM_RATE_ | awk {' print $2 '} );
#    OUTPUT_PATH="$HOME/$( cat $CONFIG_FILE | grep _OUTPUT_PATH_ | awk {' print $2 '} )";
#    DATABASEPATH="$HOME/$( cat $CONFIG_FILE | grep _DATABASEPATH_ | awk {' print $2 '} )";
    OUTPUT_PATH="$( cat $CONFIG_FILE | grep _OUTPUT_PATH_ | awk {' print $2 '} )";
    DATABASEPATH="$( cat $CONFIG_FILE | grep _DATABASEPATH_ | awk {' print $2 '} )";
    DATABASE="$DATABASEPATH/$( cat $CONFIG_FILE | grep _DATABASE_ | awk {' print $2 '} )";
    NOTIFY_ICON=$( cat $CONFIG_FILE | grep _NOTIFY_ICON_ | awk {' print $2 '} );
    DESKTOP_NOTIFICATION=$( cat $CONFIG_FILE | grep _DESKTOP_NOTIFICATION_ | awk {' print $2 '} );
    DEBUG=$( cat $CONFIG_FILE | grep _DEBUG_ | awk {' print $2 '} );
  else
    echo "Configuration file does Not Exist, copy yget.conf from template folder into /home/[user]/.local/share/yget";
    exit 3
  fi
}

# Creates the global variable $OUTPUT_TEMPLATE with the video title, id, and youtube-dl returned video quality value. 
# $OUTPUT_TEMPLATE provides the template in the format for --output option discussed in the # manual entry for youtube-dl 
# Added 2013/11/15 by OblongOrange
# Updated to transform the returned queried format from youtube-dl
# not adding "p" to the end of format, since youtube sometimes spits out videos with the h/w orientation rotated
# probably due to people setting up their recording environment incorrectly, then adjusting in post processing, 
# or those twits that record in portrait.
function Create_Output_Template {
  if [[ "$RETURNED_FORMAT" != "" ]]; then
    OUTPUT_TEMPLATE="%(title)s-%(id)s-$RETURNED_FORMAT.%(ext)s"; # add format to template if one was provided
  else
    OUTPUT_TEMPLATE="%(title)s-%(id)s.%(ext)s";      # skip format if none exists
  fi
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
        # youtube-dl --output $OUTPUT_TEMPLATE -r $DOWN_STREAM_RATE --prefer-free-formats -f "[height <=? $REQ_FMT2]" "$VIDEO_URL"; # pass all relevant data to youtube-dl
        #youtube-dl --output $OUTPUT_TEMPLATE -r $DOWN_STREAM_RATE --prefer-free-formats -f "bestvideo[height<=$REQ_FMT2]" "$VIDEO_URL"; # pass all relevant data to youtube-dl
        youtube-dl --output $OUTPUT_TEMPLATE -r $DOWN_STREAM_RATE --prefer-free-formats -f "[height<=$REQ_FMT2]" "$VIDEO_URL"; # pass all relevant data to youtube-dl
        
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

function Poll_Queue {
# add automatic screen config, check screen existence etc.
  echo "Polling ..";
  while [ 1 == 1 ]; do
    if [ -f $DATABASE ]; then
      Download;
      echo "Polling ..";
    else
      Advance_Spinner;
      sleep 2;
    fi
  done
}

#-------------------------------------------------------------------------------

function _Main {
  CheckYGetDir;
  Read_Config_File;
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
    P) Poll_Queue; ;;                          # if used with screen etc, can sit in background waiting for d/l requests
    Pcm) Poll_Clipboard; ;;
    *) Output_Options; ;;                      # help
  esac
  echo;
}

#-------------------------------------------------------------------------------

  _Main;
  exit 0;

# The End.


