#!/bin/bash
MAX_TEMP=100000 # Temperature where fans run at max speed
MIN_TEMP=50000 # Temperature where fans are off
MAX_SPEED=2700 # Maximum fan speed
MIN_SPEED=1000 # Minimum fan speed
FAN_BASENAME=/sys/class/hwmon/hwmon0/device/ # Path of the device the fan is controlled by
FAN_NAME=fan1 # Name of the fan
FAN_OUTPUT=_output # Suffix of the file name where the fan speed is written to
FAN_INPUT=_input # Suffix of the file name where the fan speed is read from
FAN_ENABLE=_manual # Suffix of the file name to enable manual fan speed control
FAN_OFF=1000 # RPM for the fan in "idle" state
ADJUST_INTERVAL=5 # Number of seconds to wait for the speed changes to apply

current_temp=$(cat /sys/class/hwmon/hwmon1/temp1_input)
current_fan_speed=$(cat $FAN_BASENAME$FAN_NAME$FAN_INPUT)

echo "Current temperature is $current_temp °C."
if [ $current_temp -le $MIN_TEMP ]
then
	echo "Current temperature is below minimum temperature of $MIN_TEMP °C."
	fan_speed=$FAN_OFF
else
	temp_span=$((MAX_TEMP-MIN_TEMP))
	speed_span=$((MAX_SPEED-MIN_SPEED))
	delta_temp=$((current_temp-MIN_TEMP))
	fan_speed=$((MIN_SPEED+delta_temp*speed_span/temp_span))
	if [ $fan_speed -gt $MAX_SPEED ]
	then
		fan_speed=$MAX_SPEED
	fi
fi
echo Setting fan speed to $fan_speed RPM...

if [ $current_fan_speed -eq 0 ] && [ $fan_speed -gt 0 ]
then
	echo "Starting up fans!"
	notify-send --expire-time=20000 "Fan speed control" "Starting up fans from $current_fan_speed RPM to $fan_speed RPM because of $current_temp °C CPU temperature"
fi

echo 1 > $FAN_BASENAME$FAN_NAME$FAN_ENABLE
echo $fan_speed > $FAN_BASENAME$FAN_NAME$FAN_OUTPUT

echo Waiting $ADJUST_INTERVAL seconds to check if fan speed is correct...
sleep $ADJUST_INTERVAL
current_fan_speed=$(cat $FAN_BASENAME$FAN_NAME$FAN_INPUT)
fan_speed_delta=$((fan_speed - current_fan_speed))
# Take absolute value of fan_speed_delta
#if [ $fan_speed_delta -lt 0 ]
#then
#	fan_speed_delta=$((fan_speed_delta*-1))
#fi
if [ $fan_speed_delta -gt 100 ]
then
	echo "Fan speed $current_fan_speed RPM is $fan_speed_delta RPM off destination value $fan_speed RPM! Error!" 1>&2
	echo "Setting fan speed to maximum ($MAX_SPEED RPM)..." 1>&2
	echo $MAX_SPEED > $FAN_BASENAME$FAN_NAME$FAN_OUTPUT
else
	echo "Fan speed is $current_fan_speed RPM, which is $fan_speed_delta RPM off the destination value of $fan_speed RPM."
	echo "Everything is okay."
fi 
