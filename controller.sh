#!/bin/bash

if [[ ! -n "$1" ]]
then
  echo "usage: $0 [name] [format]"
  exit 1
fi

if [ ! -f ./config/${1}.config ]
then
  echo "===controller=== skip...$1 config file does not exist"
  exit 1
fi

FORMAT="${2:-best}"
SAVEFOLDERGLOBAL=$(grep "Savefolder" ./config/global.config|awk -F = '{print $2}')
LOGFOLDERGLOBAL=$(grep "Logfolder" ./config/global.config|awk -F = '{print $2}')
SAVEFOLDER="$SAVEFOLDERGLOBAL/$1/"
LOGFOLDER="$LOGFOLDERGLOBAL/$1/"
#SAVEFOLDER=$(grep "Savefolder" ./config/"$1".config|awk -F = '{print $2}')
#LOGFOLDER=$(grep "Logfolder" ./config/"$1".config|awk -F = '{print $2}')
INTERVAL=$(grep "Interval" ./config/"$1".config|awk -F = '{print $2}')
LOOP=$(grep "LoopOrOnce" ./config/"$1".config|awk -F = '{print $2}')
YOUTUBE=$(grep "Youtube" ./config/"$1".config|awk -F = '{print $2}')
BILIBILI=$(grep "Bilibili" ./config/"$1".config|awk -F = '{print $2}')
TWITCH=$(grep "Twitch" ./config/"$1".config|awk -F = '{print $2}')
TWITCAST=$(grep "Twitcast" ./config/"$1".config|awk -F = '{print $2}')
HUYA=$(grep "Huya" ./config/"$1".config|awk -F = '{print $2}')
AFREE=$(grep "Afree" ./config/"$1".config|awk -F = '{print $2}')
BIGO=$(grep "Bigo" ./config/"$1".config|awk -F = '{print $2}')
DOUYU=$(grep "Douyu" ./config/"$1".config|awk -F = '{print $2}')
DOUYIN=$(grep "Douyin" ./config/"$1".config|awk -F = '{print $2}')
SEARCHID=$(grep "Search" ./config/"$1".config|awk -F = '{print $2}')
STREAMORRECORD=$(grep "StreamOrRecord" ./config/global.config|awk -F = '{print $2}')
if grep -q "StreamOrRecord" ./config/${1}.config
then
  STREAMORRECORD=$(grep "StreamOrRecord" ./config/${1}.config|awk -F = '{print $2}')
fi
RTMPURL=$(grep "Rtmpurl" ./config/global.config|awk -F = '{print $2}')
if grep -q "Rtmpurl" ./config/${1}.config
then
  RTMPURL=$(grep "Rtmpurl" ./config/${1}.config|awk -F = '{print $2}')
fi

[ "$STREAMORRECORD" != "both" ] && [ "$STREAMORRECORD" != "record" ] && [ "$STREAMORRECORD" != "stream" ] && echo "===controller=== skip...please check StreamOrRecord parameter in config file, should be record|stream|both" && exit 1
[ "$STREAMORRECORD" == "both" ] || [ "$STREAMORRECORD" == "stream" ] && [ -z "$RTMPURL" ] && echo "===controller=== skip...StreamOrRecord is \"$STREAMORRECORD\" but Rtmpurl is empty, please check StreamOrRecord and Rtmpurl parameters in config file" && exit 1

[[ ! -d "${SAVEFOLDERGLOBAL}" ]]&&mkdir ${SAVEFOLDERGLOBAL}
[[ ! -d "${LOGFOLDERGLOBAL}" ]]&&mkdir ${LOGFOLDERGLOBAL}
[[ ! -d "${SAVEFOLDER}" ]]&&mkdir ${SAVEFOLDER}
[[ ! -d "${LOGFOLDER}" ]]&&mkdir ${LOGFOLDER}

#youtube

if [[ -n "$YOUTUBE" ]]; then  
[[ ! -d "${SAVEFOLDER}youtube" ]]&&mkdir ${SAVEFOLDER}youtube
#[[ ! -d "${SAVEFOLDER}youtube/metadata" ]]&&mkdir ${SAVEFOLDER}youtube/metadata
[[ ! -d "${LOGFOLDER}youtube" ]]&&mkdir ${LOGFOLDER}youtube
sleep 5
./recorder.sh youtube $YOUTUBE $1 ${SAVEFOLDER}youtube/ ${LOGFOLDER}youtube/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi

#bil    

if [[ -n "$BILIBILI" ]]; then
[[ ! -d "${SAVEFOLDER}bilibili" ]]&&mkdir ${SAVEFOLDER}bilibili
[[ ! -d "${SAVEFOLDER}bilibili/metadata" ]]&&mkdir ${SAVEFOLDER}bilibili/metadata
[[ ! -d "${LOGFOLDER}bilibili" ]]&&mkdir ${LOGFOLDER}bilibili
sleep 5
./recorder.sh bilibili $BILIBILI $1 ${SAVEFOLDER}bilibili/ ${LOGFOLDER}bilibili/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi

#huya    

if [[ -n "$HUYA" ]]; then
[[ ! -d "${SAVEFOLDER}huya" ]]&&mkdir ${SAVEFOLDER}huya
[[ ! -d "${SAVEFOLDER}huya/metadata" ]]&&mkdir ${SAVEFOLDER}huya/metadata
[[ ! -d "${LOGFOLDER}huya" ]]&&mkdir ${LOGFOLDER}huya
sleep 5
./recorder.sh huya $HUYA $1 ${SAVEFOLDER}huya/ ${LOGFOLDER}huya/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi

#afree    

if [[ -n "$AFREE" ]]; then
[[ ! -d "${SAVEFOLDER}afree" ]]&&mkdir ${SAVEFOLDER}afree
[[ ! -d "${SAVEFOLDER}afree/metadata" ]]&&mkdir ${SAVEFOLDER}afree/metadata
[[ ! -d "${LOGFOLDER}afree" ]]&&mkdir ${LOGFOLDER}afree
sleep 5
./recorder.sh afree $AFREE $1 ${SAVEFOLDER}afree/ ${LOGFOLDER}afree/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi

#bigo
if [[ -n "$BIGO" ]]; then
[[ ! -d "${SAVEFOLDER}bigo" ]]&&mkdir ${SAVEFOLDER}bigo
[[ ! -d "${SAVEFOLDER}bigo/metadata" ]]&&mkdir ${SAVEFOLDER}bigo/metadata
[[ ! -d "${LOGFOLDER}bigo" ]]&&mkdir ${LOGFOLDER}bigo
sleep 5
./recorder.sh bigo $BIGO $1 ${SAVEFOLDER}bigo/ ${LOGFOLDER}bigo/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi

#douyu
if [[ -n "$DOUYU" ]]; then
[[ ! -d "${SAVEFOLDER}douyu" ]]&&mkdir ${SAVEFOLDER}douyu
[[ ! -d "${SAVEFOLDER}douyu/metadata" ]]&&mkdir ${SAVEFOLDER}douyu/metadata
[[ ! -d "${LOGFOLDER}douyu" ]]&&mkdir ${LOGFOLDER}douyu
sleep 5
./recorder.sh douyu $DOUYU $1 ${SAVEFOLDER}douyu/ ${LOGFOLDER}douyu/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi

#douyin
if [[ -n "$DOUYIN" ]]; then
[[ ! -d "${SAVEFOLDER}douyin" ]]&&mkdir ${SAVEFOLDER}douyin
[[ ! -d "${SAVEFOLDER}douyin/metadata" ]]&&mkdir ${SAVEFOLDER}douyin/metadata
[[ ! -d "${LOGFOLDER}douyin" ]]&&mkdir ${LOGFOLDER}douyin
sleep 5
./recorder.sh douyin $DOUYIN $1 ${SAVEFOLDER}douyin/ ${LOGFOLDER}douyin/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi

#twitch twitch_id [format] [loop|once] [interval] [savefolder]

if [[ -n "$TWITCH" ]]; then
[[ ! -d "${SAVEFOLDER}twitch" ]]&&mkdir ${SAVEFOLDER}twitch
[[ ! -d "${SAVEFOLDER}twitch/metadata" ]]&&mkdir ${SAVEFOLDER}twitch/metadata
[[ ! -d "${LOGFOLDER}twitch" ]]&&mkdir ${LOGFOLDER}twitch
sleep 5
./recorder.sh twitch $TWITCH $1 ${SAVEFOLDER}twitch/ ${LOGFOLDER}twitch/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi

#TWITCAST
if [[ -n "$TWITCAST" ]]; then
[[ ! -d "${SAVEFOLDER}twitcast" ]]&&mkdir ${SAVEFOLDER}twitcast
[[ ! -d "${SAVEFOLDER}twitcast/metadata" ]]&&mkdir ${SAVEFOLDER}twitcast/metadata
[[ ! -d "${LOGFOLDER}twitcast" ]]&&mkdir ${LOGFOLDER}twitcast
#sleep 5
#[[ ! -f "${SAVEFOLDER}twitcast/livedl" ]]&&ln ./livedl ${SAVEFOLDER}twitcast/
sleep 5
./recorder.sh twitcast $TWITCAST $1 ${SAVEFOLDER}twitcast/ ${LOGFOLDER}twitcast/ $FORMAT $LOOP $INTERVAL $STREAMORRECORD $RTMPURL &
sleep 10
fi
#OPENREC
#./record_openrec.sh $OPENRCE $FORAMT $LOOP $INTERVAL ${SAVEFOLDER}&

wait
