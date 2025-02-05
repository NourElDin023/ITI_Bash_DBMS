#!/usr/bin/bash

showMainMenu() {
  mkdir -p "$HOME/databases"
  cd "$HOME/databases"

  choice=$(kdialog --menu "Main Menu" 1 "Create Database" 2 "List Databases" 3 "Connect To Databases" 4 "Drop Database")

  if [ "$?" = 0 ]; then # $? if the last command was successful it will be 0 otherwise 1

    # * Create Database
    if [ "$choice" = 1 ]; then
      name=$(kdialog --title "You Chose Create Database" --inputbox "Enter Database Name:")
      # name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      name=$(echo "$name" | awk '{$1=$1;print}') #Trim Both Leading and Trailing Spaces

      if [ -d "$name" ]; then
        kdialog --sorry "error: Database Name already used" #Check if dir exist
      elif [[ ! "$name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        kdialog --sorry "Error: Database Name can only contain letters, numbers, and underscores and one word"
      else
        mkdir -p "$name"
        kdialog --msgbox "Database $name Created Successfully"
      fi

    # * list Databases
    elif [ "$choice" = 2 ]; then
      # reset the .databaseNames.txt file in case of a database add or removed and List current databases in an file each on one line
      ls $HOME/databases -l | grep '^d' | awk 'BEGIN {print "Your Databases:\n"} {print "\t"NR": "$9"\n\t----------"} END { print "\nTotal Databases: "NR }' >.databaseNames.txt
      kdialog --textbox .databaseNames.txt

    # * Connect To Databases
    elif [ "$choice" = 3 ]; then
      # kdialog --inputbox "Please type Database Name"
      name=$(kdialog --inputbox "Please type Database Name")
      echo $name
      kdialog --msgbox "You Chose Connect To Database"

    # * Drop Database
    elif [ "$choice" = 4 ]; then
      kdialog --msgbox "You Chose Drop Database"
    fi
  elif [ "$?" = 1 ]; then
    kdialog --sorry "You Chose Cancel"
  fi
}

showMainMenu
