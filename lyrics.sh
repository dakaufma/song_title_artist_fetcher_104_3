#!/bin/bash

function get_current_track_url() {
	DBUS_DEST="org.mpris.MediaPlayer2.vlc"
	DBUS_PATH="/org/mpris/MediaPlayer2"
	DBUS_METHOD="org.freedesktop.DBus.Properties.Get"
	GET_TARGET="string:org.mpris.MediaPlayer2.Player"
	PROPERTY="string:Metadata"

	XESAM_URL=$(dbus-send --print-reply=literal --dest=$DBUS_DEST "$DBUS_PATH" "$DBUS_METHOD" "$GET_TARGET" "$PROPERTY" | grep -o 'file://\S*')

	echo "$XESAM_URL"
}

function decode_url() {
	LINE="$1"
	VALUE_ONLY=$(echo "$LINE" | tr " " "\n" | grep -o "file://.*")
 	DECODED=$(echo "$VALUE_ONLY" | sed 's/%\([0-9A-F][0-9A-F]\)/\\\\x\1/g' | xargs echo -e | cut -c 8-)

 	echo "$DECODED"
}

function track_path_to_lyrics_path() {
	TRACK_PATH="$1"
	PARENT_PATH=$(dirname "${TRACK_PATH}")
	LYRICS_PATH="${PARENT_PATH}/lyrics.txt"
	echo "${LYRICS_PATH}"
}

function display_lyrics() {
	less -c --quit-on-intr "$1"
}

LYRICS_FIFO=$(echo "/tmp/lyrics_fifo_$$")
rm -f "$LYRICS_FIFO"
mkfifo "$LYRICS_FIFO"
exec 3<> "$LYRICS_FIFO";

function cleanup() {
	jobs -p | xargs kill -9
	rm -f "$LYRICS_FIFO"
}
trap cleanup EXIT

INIT_TRACK_URL=$(get_current_track_url)
INIT_TRACK_PATH=$(decode_url "$INIT_TRACK_URL")
INIT_LYRICS_PATH=$(track_path_to_lyrics_path "$INIT_TRACK_PATH")

OLD_LYRICS_PATH="$INIT_LYRICS_PATH"
echo "$OLD_LYRICS_PATH" > "$LYRICS_FIFO"

dbus-monitor --monitor "type=signal,interface=org.freedesktop.DBus.Properties,path=/org/mpris/MediaPlayer2,member=PropertiesChanged" | while read line
do
	if echo "$line" | grep -q 'file://'
	then
		URL=$(echo "$line" | sed 's/.*string "\(.*\)"/\1/')
		TRACK_PATH=$(decode_url "$URL")
		LYRICS_PATH=$(track_path_to_lyrics_path "$TRACK_PATH")

		if [ "$LYRICS_PATH" != "$OLD_LYRICS_PATH" ]
		then
			OLD_LYRICS_PATH="$LYRICS_PATH"
			pgrep -P $$ less | xargs kill -9 2>/dev/null
			echo "$OLD_LYRICS_PATH" > "$LYRICS_FIFO"
		fi
	fi
done &

while true
do
	if read line
	then
		echo "$line"
		display_lyrics "$line" 2>/dev/null
	fi
done <"$LYRICS_FIFO"
