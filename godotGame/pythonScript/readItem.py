#!/usr/bin/env python

import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522
from time import sleep

reader = SimpleMFRC522()

try:
    tag, text = reader.read()
    print(text)
    GPIO.cleanup()

except:
    GPIO.cleanup()