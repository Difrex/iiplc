#!/bin/bash

# Debug server
plackup iiplc.app

# Production
# starman -l 127.0.0.1:5000 run.pl whatever
