#!/bin/bash

. "FUNCTION.sh"

if [ ! -z "$1" ]
then
    $1
else
    echo "Yo bro you gotta put an argument LOL."
fi