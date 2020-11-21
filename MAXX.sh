#!/bin/bash

. "FUNCTIONS.sh"

SHOW_HEADER
if  [ $# -eq 0 ]
then
    echo -e "${C_ERROR} Yo bro you gotta put an argument ${F_BOLD}LOL${NO_FORMAT}."
    SHOW_ALL_HELP
    exit
else
    $1
fi