#!/bin/bash
echo -n x > /dev/ttyUSB0
echo -n s > /dev/ttyUSB0
cat Assembly/TestSRecord.S68 | while read line
do
   sleep 0.05
   echo  $line >> /dev/ttyUSB0 # This echo includes \r but not \n
done
echo -n e > /dev/ttyUSB0
#sleep 1
screen /dev/ttyUSB0 9600
