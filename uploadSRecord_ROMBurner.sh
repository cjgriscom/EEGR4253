#!/bin/bash
stty -F /dev/ttyUSB0 19200
#echo -n r > /dev/ttyUSB0
#echo -n r > /dev/ttyUSB0
#echo -n r > /dev/ttyUSB0
#echo -n r > /dev/ttyUSB0
#echo -n r > /dev/ttyUSB0
echo -n r > /dev/ttyUSB0
echo -n s > /dev/ttyUSB0
cat /dev/ttyUSB0 &
sleep 0.1
cat Assembly/ROMBurner.S68 | while read line
do
   sleep .02
   echo $line >> /dev/ttyUSB0 # This echo includes \r but not \n
done
sleep 0.2
#echo -n e > /dev/ttyUSB0
sleep .2
killall cat
screen /dev/ttyUSB0 19200
