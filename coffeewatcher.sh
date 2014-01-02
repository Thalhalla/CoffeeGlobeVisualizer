#!/bin/bash
echo "coffee will now watch src for changes and compile them into the compiled directory"
coffee -cwo compiled src &
echo "now watching"&
