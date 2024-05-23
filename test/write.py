#!/usr/bin/env python

import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522
from time import sleep

reader = SimpleMFRC522()

try:
    while True:
        text = input('New Data:')
        print('Now place your tag to write')
        reader.write(text)
        print('Written')
        sleep(2)

except KeyboardInterrupt:
    GPIO.cleanup()
