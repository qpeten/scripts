#!/bin/bash


#orig was 23:27 || 00 11 10 01
# 24 23 27

A="24"
B="23"
C="27"

gpioOn="1" #Sont inverses
gpioOff="0"

if [ $1 -eq 30 ]
then
	gpio write "$A" "$gpioOff"
	gpio write "$B" "$gpioOff"
	gpio write "$C" "$gpioOn"
elif [ $1 -eq 40 ]
then
        gpio write "$A" "$gpioOn"
        gpio write "$B" "$gpioOn"
        gpio write "$C" "$gpioOff"
elif [ $1 -eq 46 ]
then
        gpio write "$A" "$gpioOff"
        gpio write "$B" "$gpioOff"
        gpio write "$C" "$gpioOff"
elif [ $1 -eq 55 ]
then
        gpio write "$A" "$gpioOn"
        gpio write "$B" "$gpioOn"
        gpio write "$C" "$gpioOn"
elif [ $1 -eq 67 ]
then
        gpio write "$A" "$gpioOn"
        gpio write "$B" "$gpioOff"
        gpio write "$C" "$gpioOn"

elif [ $1 -eq 75 ]
then
        gpio write "$A" "$gpioOff"
        gpio write "$B" "$gpioOn"
        gpio write "$C" "$gpioOff"
fi
