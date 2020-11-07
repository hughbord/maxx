#!/bin/bash

. "FUNCTIONS.sh"

if  [ $# -eq 0 ]
then
    echo -e "${C_ERROR} Yo bro you gotta put an argument ${F_BOLD}LOL${NO_FORMAT}."
    exit
else
    $1
fi