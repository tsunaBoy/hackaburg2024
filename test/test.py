#!/usr/bin/env python

import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522
import subprocess

reader = SimpleMFRC522()

def readTag() -> str:
    print('Place your Tag...')
    tag, text = reader.read()
    print('id: ', tag, '\ttext: ', text)
    return '' if (text == None) else text.strip()


def main():
    test = readTag()

    if test == 'help':
        subprocess.run(['feh', '/home/bazi/hackaburg24/test.png'])

    GPIO.cleanup()
        

if __name__=='__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('ctrl-c')
        GPIO.cleanup()
        # raise
