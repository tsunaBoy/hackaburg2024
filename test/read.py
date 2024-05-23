#!/usr/bin/env python

import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522
from time import sleep

reader = SimpleMFRC522()

try:
    while True:
        print('Place your Tag...')
        tag, text = reader.read()
        print('id: ', tag, '\ttext: ', text)
        sleep(2)

except KeyboardInterrupt:
    GPIO.cleanup()
    # raise
