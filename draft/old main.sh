#!/usr/bin/bash
source ./table.sh

showMainMenu() {
  mkdir -p "$HOME/databases"
  cd "$HOME/databases"

  choice=$(kdialog --menu "Main Menu" 1 "Create Database" 2 "List Databases" 3 "Connect To Databases" 4 "Drop Database")

  if [ "$?" = 0 ]; then # ? if the last command was successful it will be 0 otherwise 1

    # * Create Database
    if [ "$choice" = 1 ]; then
      name=$(kdialog --title "You Chose Create Database" --inputbox "Enter Database Name:")
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
      tableMenu
      # name=$(kdialog --inputbox "Please type Database Name")
      # name=$(echo "$name" | awk '{$1=$1;print}')

      # if [ -d "$name" ]; then
      #   cd "$name"
      #   kdialog --msgbox "Successfully connected to database: $name"
      # else
      #   kdialog --sorry "Error: Database '$name' doesn't exist"
      # fi

    # # * Drop Database
    elif [ "$choice" = 4 ]; then
      menu_entries=()
      while IFS= read -r db; do
        ((counter++))
        menu_entries+=("$counter" "$db")
      done < <(find "$HOME/databases" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

      if [ ${#menu_entries[@]} -eq 0 ]; then
        kdialog --sorry "No databases found."
      else
        db_name=$(kdialog --menu "Select a Database to Drop" "${menu_entries[@]}")
        if [ "$?" = 0 ] && [ -n "$db_name" ]; then
          selected_db=$(echo "${menu_entries[@]}" | awk -v num="$db_name" '{print $num}')
          if kdialog --yesno "Are you sure you want to delete database '$selected_db'?"; then
            rm -fr "$selected_db"
            kdialog --msgbox "Database '$selected_db' deleted successfully"
          fi
        fi
      fi

    fi

  elif [ "$?" = 1 ]; then
    kdialog --sorry "You Chose Cancel"
    return
  fi
}

showMainMenu
