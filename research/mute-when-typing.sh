# Find via `xinput --list --name-only`
KEYBOARD="Kinesis Advantage2 Keyboard"
# Find via `pactl list sources | grep Name: | awk -F:\  '{print $2}' | grep input`
AUDIO_SOURCE="alsa_input.usb-Plantronics_Plantronics_Savi_7xx-M-00.analog-mono"
AUDIO_SOURCE="alsa_input.usb-0b0e_Jabra_SPEAK_510_USB_501AA5D89CCB020A00-00.analog-mono"
# touched on keypress
KEYPRESS_FILE=keypress
# exists while recent keypres
MUTE_FILE=mute

cd $(mktemp -d)
# set -x
# set -e
(
while read keypress; do
    touch $KEYPRESS_FILE
done < <(xinput test-xi2 --root "$KEYBOARD")
) 2>&1 &

(
    while read file; do
        if [ $file == $KEYPRESS_FILE ] ; then
            touch $MUTE_FILE
        fi
    done < <(inotifywait  -e create,attrib,modify --format '%f' --quiet . --monitor)
) 2>&1 &

(
    while read file; do
        if [ $file == $MUTE_FILE ] ; then
            echo "UNMUTING"
            pactl set-source-mute $AUDIO_SOURCE 0
            # mute with alsa
            # amixer -D pulse sset Capture cap
            # mute everything with pactl
            # pactl list sources | grep Name: | awk -F:\  '{print $2}' | grep -v monitor \
            #     | xargs -n 1 -I X pactl set-source-mute X 0
            # get the currenty active window, send alt+a to mute-unmute
            # aw=$(xdotool getactivewindow)
            # xdotool search --name 'Zoom Meeting ID: .*' \
            #         windowactivate --sync \
            #         key alt+a \
            #         windowactivate $aw
        fi
    done < <(inotifywait  -e delete --format '%f' --quiet . --monitor)
) 2>&1 &

(
    while read file; do
        if [ $file == $MUTE_FILE ] ; then
            echo "MUTING"
            pactl set-source-mute $AUDIO_SOURCE 1
            # amixer -D pulse sset Capture nocap
            # unmute everything with pactl
            # pactl list sources | grep Name: | awk -F:\  '{print $2}' | grep -v monitor \
            #     | xargs -n 1 -I X pactl set-source-mute X 1
            # aw=$(xdotool getactivewindow)
            # xdotool search --name 'Zoom Meeting ID: .*' \
            #         windowactivate --sync \
            #         key alt+a \
            #         windowactivate $aw
        fi
    done < <(inotifywait  -e create --format '%f' --quiet . --monitor)
) 2>&1 &

(
    while true ; do
        if [ ! -f $KEYPRESS_FILE ] ; then
            sleep 0.1
            continue
        elif [ ! -f $MUTE_FILE ] ; then
            sleep 0.1
            continue
        fi
        LAST_KEYSTROKE_TIME=$(ls -l  --time-style=+%H%M%S%N $KEYPRESS_FILE | awk '{print $6}')
        CURRENT_TIME=$(date +%H%M%S%N)
        TIME_SINCE_LAST_KEYSTROKE=$(($CURRENT_TIME - $LAST_KEYSTROKE_TIME))
        if [ $TIME_SINCE_LAST_KEYSTROKE -ge 200000000 ] ; then
            if [ -f $MUTE_FILE ] ; then
                rm $MUTE_FILE && sleep 0.1 && rm -f $MUTE_FILE
            fi
        fi
    done
) 2>&1 &

wait
