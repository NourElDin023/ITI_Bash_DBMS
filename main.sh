#!/usr/bin/bash

showMainMenu() {
  mkdir -p "$HOME/databases"
  cd "$HOME/databases"

  choice=$(kdialog --menu "Main Menu" 1 "Create Database" 2 "List Databases" 3 "Connect To Databases" 4 "Drop Database")

  if [ "$?" = 0 ]; then # $? if the last command was successful it will be 0 otherwise 1
    if [ "$choice" = 1 ]; then
      name=$(kdialog --title "You Chose Create Database" --inputbox "Enter Database Name:")
      # TODO: check if database name has a special character
      #
      # if [ $name ==  *"/"* || ]; then
      #   echo $name
      # fi
      # ls -l | grep "$name" # if db name already exists
      #
      # We can use `command ls -d $name` then ensure that the output
      # has no such file or directory
      mkdir -p "$name"
      kdialog --msgbox "Database $name Created Successfully"
    elif [ "$choice" = 2 ]; then
      kdialog --msgbox "You Chose List Database"
    elif [ "$choice" = 3 ]; then
      kdialog --msgbox "You Chose Connect To Database"
    elif [ "$choice" = 4 ]; then
      kdialog --msgbox "You Chose Drop Database"
    fi
  elif [ "$?" = 1 ]; then
    kdialog --sorry "You Chose Cancel"
  fi
}

showMainMenu
