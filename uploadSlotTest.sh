#!/bin/bash
stty -F /dev/ttyUSB0 19200
#echo -n r > /dev/ttyUSB0
#echo -n r > /dev/ttyUSB0
#echo -n r > /dev/ttyUSB0
#echo -n r > /dev/ttyUSB0
#echo -n r > /dev/ttyUSB0
echo -n r > /dev/ttyUSB0
#echo -n a > /dev/ttyUSB0
echo -n S > /dev/ttyUSB0
cat /dev/ttyUSB0 &
sleep 0.5
cat Assembly/TestSRecord.S68 | while read line
do
   sleep .1
   echo $line >> /dev/ttyUSB0 # This echo includes \r but not \n
   echo $line >&2
done
sleep 1
#echo -n e > /dev/ttyUSB0
sleep 1
killall cat
screen /dev/ttyUSB0 19200
