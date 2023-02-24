#!/bin/bash
# Stream Recorder

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "usage: $0 site channel_id [name] [savefolder] [logfolder] [format] [loop|once] [interval] [streamorrecord] [rtmpurl]"
  exit 1
fi


# Set the default value of parameters
SITE="${1:-youtube}"
CHANNELID="$2"
NAME="$3"
SAVEFOLDER="$4"
LOGFOLDER="$5"
FORMAT="${6:-best}"
LOOPORONCE="${7:-once}"
INTERVAL="${8:-30}"
STREAMORRECORD="${9:-record}"
RTMPURL="${10}"
AUTOBACKUP=$(grep "Autobackup" ./config/global.config|awk -F = '{print $2}')
SAVEFORMAT=$(grep "Saveformat" ./config/global.config|awk -F = '{print $2}')

# Construct full URL if only channel id given
[ "$SITE" == "youtube" ] && LIVE_URL="https://www.youtube.com/channel/$CHANNELID/live"
[ "$SITE" == "bilibili" ] && LIVE_URL="https://live.bilibili.com/$CHANNELID"
[ "$SITE" == "twitch" ] && LIVE_URL="https://www.twitch.tv/$CHANNELID"
[ "$SITE" == "twitcast" ] && LIVE_URL="https://twitcasting.tv/$CHANNELID"
[ "$SITE" == "huya" ] && LIVE_URL="https://www.huya.com/$CHANNELID"
[ "$SITE" == "afree" ] && LIVE_URL="https://play.afreecatv.com/$CHANNELID"
[ "$SITE" == "bigo" ] && LIVE_URL="https://www.bigo.tv/$CHANNELID"
[ "$SITE" == "douyu" ] && LIVE_URL="https://www.douyu.com/$CHANNELID"


while true; do
  # Monitor live streams of specific channel
  while true; do
    LOG_PREFIX="$(date +'[%Y-%m-%d %H:%M:%S]') ===$SITE==="
    echo "$LOG_PREFIX Checking $LIVE_URL..."
    echo "$LOG_PREFIX Try to get current live stream of $LIVE_URL"

    #Check whether the channel is live
    #curl -s -N https://www.youtube.com/channel/$1/live|grep -q '\\"isLive\\":true' && break
    #wget -q -O- $LIVE_URL|grep -q '\\"isLive\\":true' && break
    [ "$SITE" == "youtube" ] && wget -q -O- "$LIVE_URL"|grep 'www.youtube.com/embed/live_stream'|grep -q '\"isLive\":true' && break
    if [ "$SITE" == "bilibili" ]
    then
      YOUTUBEURL=$(grep "Youtube" ./config/"$NAME".config|awk -F = '{print $2}')
      if [ -n "$YOUTUBEURL" ] && wget -q -O- "https://www.youtube.com/channel/$YOUTUBEURL/live" |grep 'www.youtube.com/embed/live_stream'|grep -q '\"isLive\":true'
      then
        echo "$LOG_PREFIX skip...youtube channel is already streaming!"
      else
        wget -q -O- "https://api.live.bilibili.com/room/v1/Room/get_info?room_id=$CHANNELID&from=room"|grep -q '\"live_status\"\:1' && break
      fi
    fi
    	if [ "$SITE" == "huya" ]
      then
        curl "https://mp.huya.com/cache.php?m=Live&do=profileRoom&roomid=$CHANNELID"|grep -q 'baseS' && break
    fi
	if [ "$SITE" == "douyu" ]
      then
        curl -A "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.0)" "https://open.douyucdn.cn/api/RoomApi/room/$CHANNELID"|grep -q '"room_status":"1"' && break
    fi
	if [ "$SITE" == "afree" ]
      then
        curl -A "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.0)" "https://bjapi.afreecatv.com/api/$CHANNELID/station"|grep -q 'password' && break
    fi
	if [ "$SITE" == "bigo" ]
      then
        curl -A "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.0)" "https://www.bigo.tv/OInterface/getVideoParam?bigoId=$CHANNELID"|grep -q 'tmp' && break
    fi
    if [ "$SITE" == "twitch" ]
    then
      TWITCHKEY=$(grep "Twitchkey" ./config/global.config|awk -F = '{print $2}')
      TWITCHPWD=$(grep "Twitchpwd" ./config/global.config|awk -F = '{print $2}')
      if [ -z "$TWITCHKEY" ] || [ -z "$TWITCHPWD" ]
      then
        echo "$LOG_PREFIX skip...Twitchkey or Twitchpwd is empty!"
      else
        #wget -q -O- --header="Client-ID: $TWITCHKEY" https://api.twitch.tv/helix/streams?user_login=$CHANNELID|grep -q \"type\":\"live\" && break
        TWITCHTOKEN=$(curl -X POST 'https://id.twitch.tv/oauth2/token?client_id='$TWITCHKEY'&client_secret='$TWITCHPWD'&grant_type=client_credentials' | awk -F '[,:"]+' '{for(i=1;i<=NF-1;i++)if($i ~ /access_token/)print $(i+1)}')
        wget -q -O- --header="Client-ID: $TWITCHKEY" --header="Authorization: Bearer ${TWITCHTOKEN}" https://api.twitch.tv/helix/streams?user_login=$CHANNELID | grep -q \"type\":\"live\" && break
      fi
    fi
    if [ "$SITE"="twitcast" ]
    then
      wget -q -O- "https://twitcasting.tv/streamserver.php?target=$CHANNELID&mode=client" | grep -q '"live":true' && break
    fi
    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after $INTERVAL seconds..."
    sleep $INTERVAL
  done
  #Create save folder by date
  FOLDERBYDATE="$(date +"%Y%m%d")"
  [[ ! -d "${SAVEFOLDER}${FOLDERBYDATE}" ]]&&mkdir ${SAVEFOLDER}${FOLDERBYDATE}
  #[[ ! -d "${SAVEFOLDER}${FOLDERBYDATE}/metadata" ]]&&mkdir ${SAVEFOLDER}${FOLDERBYDATE}/metadata

  #Fetch live information
  if [ "$SITE" == "youtube" ]
  then
    METADATA=$(yt-dlp --get-id --get-title --get-thumbnail --get-description \
    --no-check-certificate --no-playlist --playlist-items 1 \
    "${LIVE_URL}" 2>/dev/null)
    [ -z "$METADATA" ] && echo "$LOG_PREFIX skip...youtube metadata is empty!" && continue
    # Extract stream title
    #Title=$(echo "$METADATA" | sed -n '1p'|sed 's#[()/\\!-\$]##g')
    # Extract video id of live stream
    ID=$(echo "$METADATA" | sed -n '2p')
    # Extract stream cover url
    #COVERURL=$(echo "$METADATA" | sed -n '3p')
    COVERURL="https://i.ytimg.com/vi/${ID}/maxresdefault.jpg"
    #FNAME="youtube_${Title}_$(date +"%Y%m%d_%H%M%S")_${ID}.${SAVEFORMAT}"
    FNAME="youtube_$(date +"%Y%m%d_%H%M%S")_${ID}.${SAVEFORMAT}"
    # Also save the metadata and cover to file
    if [ "$STREAMORRECORD" != "stream" ]; then
      echo "$METADATA" > "${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}.info.txt"
      wget -O "${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}.jpg" "$COVERURL"
    fi
  fi
  if [ "$SITE" == "bilibili" ]
  then
    # Savetitle
    TITLE=$(you-get -i "$LIVE_URL"|sed -n '2p'|cut -c 22-|cut -d '.' -f 1|sed 's/[()/\\!-\$]//g')
    # Record using MPEG-2 TS format to avoid broken file caused by interruption
    FNAME="bil_${CHANNELID}_$(date +"%Y%m%d_%H%M%S").${SAVEFORMAT}"
  fi
  if [ "$SITE" == "twitch" ]
  then
    METADATA=$(youtube-dl --get-id --get-title --get-description "$LIVE_URL")
    #TITLE=$(echo "$METADATA" | sed -n '3p'|sed 's/[()/\\!-\$]//g')
    ID=$(echo "$METADATA" | sed -n '2p')
    #FNAME="twitch_${ID}_${TITLE}_$(date +"%Y%m%d_%H%M%S").${SAVEFORMAT}"
    FNAME="twitch_$(date +"%Y%m%d_%H%M%S")_${ID}.${SAVEFORMAT}"
    [ "$STREAMORRECORD" != "stream" ] && echo "$METADATA" > "${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}.info.txt"
  fi
  if [ "$SITE" == "twitcast" ]
  then
    #MOVIEID=$(wget -q -O- ${LIVE_URL} | grep data-movie-id | awk -F '[=\"]+' '{for(i=1;i<=NF-1;i++)if($i ~ /data-movie-id/)print $(i+1)}')
    #ID=$(echo "$CHANNELID"|sed 's/:/：/') 
    #LIVEDL_FNAME="${ID}_${MOVIEID}.${SAVEFORMAT}" 
    FNAME="twitcast_$(date +"%Y%m%d_%H%M%S")_${CHANNELID}.${SAVEFORMAT}"
  fi
  if [ "$SITE" == "huya" ]
  then
    # Savetitle
    TITLE=$(you-get -i "$LIVE_URL"|sed -n '2p'|cut -c 22-|cut -d '.' -f 1|sed 's/[()/\\!-\$]//g')
    # Record using MPEG-2 TS format to avoid broken file caused by interruption
    FNAME="huya_${CHANNELID}_${TITLE}_$(date +"%Y%m%d_%H%M%S").${SAVEFORMAT}"
  fi
  if [ "$SITE" == "afree" ]
  then
    # Savetitle
    TITLE=$(you-get -i "$LIVE_URL"|sed -n '2p'|cut -c 22-|cut -d '.' -f 1|sed 's/[()/\\!-\$]//g')
    # Record using MPEG-2 TS format to avoid broken file caused by interruption
    FNAME="afree_${CHANNELID}_${TITLE}_$(date +"%Y%m%d_%H%M%S").${SAVEFORMAT}"
  fi   
  if [ "$SITE" == "bigo" ]
  then
    # Savetitle
    TITLE=$(you-get -i "$LIVE_URL"|sed -n '2p'|cut -c 22-|cut -d '.' -f 1|sed 's/[()/\\!-\$]//g')
    # Record using MPEG-2 TS format to avoid broken file caused by interruption
    FNAME="Bigo_${CHANNELID}_${TITLE}_$(date +"%Y%m%d_%H%M%S").${SAVEFORMAT}"
  fi
  if [ "$SITE" == "douyu" ]
  then
    # Savetitle
    TITLE=$(you-get -i "$LIVE_URL"|sed -n '2p'|cut -c 22-|cut -d '.' -f 1|sed 's/[()/\\!-\$]//g')
    # Record using MPEG-2 TS format to avoid broken file caused by interruption
    FNAME="Douyu_${CHANNELID}_$(date +"%Y%m%d_%H%M%S").${SAVEFORMAT}"
  fi
  
  # Print logs
  echo "$LOG_PREFIX Start recording, stream saved to ${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}"
  [ "$SITE" == "youtube" ] || [ "$SITE" == "twitch" ] && echo "$LOG_PREFIX metadata saved to ${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}.info.txt"
  [ "$SITE" == "youtube" ] && echo "$LOG_PREFIX cover saved to ${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}.jpg"
  echo "$LOG_PREFIX recording log saved to ${LOGFOLDER}${FNAME}.log, streaming log saved to ${LOGFOLDER}${FNAME}.streaming.log"
  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  # Start recording
  # ffmpeg -i "$M3U8_URL" -codec copy -f mpegts "savevideo/$FNAME" > "savevideo/$FNAME.log" 2>&1
  # Use streamlink "--hls-live-restart" parameter to record for HLS seeking support
  #M3U8_URL=$(streamlink --stream-url "https://www.youtube.com/watch?v=${ID}" "best")
  #ffmpeg   -i "$M3U8_URL" -codec copy   -f hls -hls_time 3600 -hls_list_size 0 "${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}" > "${LOGFOLDER}${FNAME}.log" 2>&1

  if [ "$SITE" == "douyu" ]
  then
    #DID=$(you-get -u "$LIVE_URL"|sed -n '8p'|cut -c 33-|cut -d '.' -f 1)
    DID=$(you-get -u "$LIVE_URL"|sed -n '8p'|cut -c 28-|cut -d '/' -f 2|cut -d '.' -f 1)
    REAL_URL="https://akm-tct.douyucdn.cn/live/${DID}.flv?uuid="
      if [ "$STREAMORRECORD" == "both" ] 
      then
          ffmpeg \
          -headers "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.42" \
          -headers "referer: https://www.douyu.com/${CHANNELID}" \
          -re -i "$REAL_URL" \
          -vcodec copy -acodec aac -strict -2 \
          -f flv -y -flvflags no_duration_filesize "${RTMPURL}" \
          "${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}"  \
          > "${LOGFOLDER}${FNAME}.streaming.log" 2>&1 
      elif [ "$STREAMORRECORD" == "record" ]
      then
          ffmpeg \
          -headers "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.42" \
          -headers "referer: https://www.douyu.com/${CHANNELID}" \
          -re -i "$REAL_URL" \
          -vcodec copy -acodec aac -strict -2 \
          -f flv -y -flvflags no_duration_filesize \
          "${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}"  \
          > "${LOGFOLDER}${FNAME}.log" 2>&1 
          STREAMSUCCESS=$?
      elif [ "$STREAMORRECORD" == "stream" ]
      then
          ffmpeg \
          -headers "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.42" \
          -headers "referer: https://www.douyu.com/${CHANNELID}" \
          -re -i "$REAL_URL" \
          -vcodec copy -acodec aac -strict -2 \
          -f flv -y -flvflags no_duration_filesize "${RTMPURL}" \
          > "${LOGFOLDER}${FNAME}.streaming.log" 2>&1 
      fi
  elif [ "$SITE" != "douyu" ]
  then
      if [ "$STREAMORRECORD" == "both" ] 
      then
         streamlink "$LIVE_URL" "1080p,1080p60,best" -o - | ffmpeg -re -i pipe:0 \
         -codec copy -f mpegts "${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}" \
         -vcodec copy -acodec aac -strict -2 -f flv "${RTMPURL}" \
         > "${LOGFOLDER}${FNAME}.streaming.log" 2>&1
         STREAMSUCCESS=$?
      elif [ "$STREAMORRECORD" == "record" ]
      then
         streamlink --loglevel trace -o "${SAVEFOLDER}${FOLDERBYDATE}/${FNAME}" \
         "$LIVE_URL" "1080p,1080p60,1440p,1440p60,best" > "${LOGFOLDER}${FNAME}.log" 2>&1
      elif [ "$STREAMORRECORD" == "stream" ]
      then
         streamlink "$LIVE_URL" "1080p,1080p60,best" -o - | ffmpeg -re -i pipe:0 \
         -vcodec copy -acodec aac -strict -2 -f flv "${RTMPURL}" \
         > "${LOGFOLDER}${FNAME}.streaming.log" 2>&1   
      fi
  fi
  # backup stream if autobackup is on 
  sleep 5 
  if [ "$SITE" == "douyu" ]
  then  

      if [ "$AUTOBACKUP" == "on" ] && [ "$STREAMORRECORD" != "stream" ]
      then
      REALTIME=$(date +%s)
      FILETIME=$(stat -c %Y ${LOGFOLDER}${FNAME}.log)
      TIMEDIF=$[$REALTIME - $FILETIME]        
        if ([ "$STREAMORRECORD" == "record" ] && tail -n 5 "${LOGFOLDER}${FNAME}.log"|grep -q "muxing overhead") || [ $TIMEDIF -gt 60 ] || [ "X$STREAMSUCCESS" == "X0" ]
        then
           echo "$LOG_PREFIX more than 60 second, stop and next step."
           ./autobackup.sh $NAME $SITE $FOLDERBYDATE $FNAME &
        else
           echo "$LOG_PREFIX stream record fail, check ${LOGFOLDER}${FNAME}.log and ${LOGFOLDER}${FNAME}.streaming.log for detail."
        fi
      fi  
  elif [ "$SITE" != "douyu" ]
  then
      if [ "$AUTOBACKUP" == "on" ] && [ "$STREAMORRECORD" != "stream" ]
      then
        if ([ "$STREAMORRECORD" == "record" ] && tail -n 5 "${LOGFOLDER}${FNAME}.log"|grep -q "Stream ended") || [ "X$STREAMSUCCESS" == "X0" ]
        then
         ./autobackup.sh $NAME $SITE $FOLDERBYDATE $FNAME &
        else
           echo "$LOG_PREFIX stream record fail, check ${LOGFOLDER}${FNAME}.log and ${LOGFOLDER}${FNAME}.streaming.log for detail."
        fi
      fi 
  fi

  # Exit if we just need to record current stream
  LOG_PREFIX="$(date +"[%Y-%m-%d %H:%M:%S]") ===$SITE==="
  echo "$LOG_PREFIX Live stream recording stopped."
  [[ "$LOOPORONCE" == "once" ]] && break
done
