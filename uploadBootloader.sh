#!/bin/bash
stty -F /dev/ttyUSB0 19200
echo -n x > /dev/ttyUSB0
echo -n x > /dev/ttyUSB0
echo -n x > /dev/ttyUSB0
echo -n x > /dev/ttyUSB0
echo -n x > /dev/ttyUSB0
echo -n x > /dev/ttyUSB0
cat /dev/ttyUSB0 &
sleep 0.01
#echo -n ' ' > /dev/ttyUSB0
echo -n 'b' > /dev/ttyUSB0
sleep 1 # Wait for chip erase
foo=`cat Assembly/Bootloader.S68` ; for (( i=0; i<${#foo}; i++ )); do sleep 0.00025;  echo -n "${foo:$i:1}"; done > /dev/ttyUSB0
echo -n 'k' > /dev/ttyUSB0
#echo -n e > /dev/ttyUSB0
sleep .2
killall cat
screen /dev/ttyUSB0 19200
