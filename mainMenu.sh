#!/usr/bin/bash
source ./tableMenu.sh

mainMenu() {
    mkdir -p "$HOME/databases"
    cd "$HOME/databases"

    while true; do
        choice=$(kdialog --menu "Main Menu" \
            1 "Create Database" \
            2 "List Databases" \
            3 "Connect To Database" \
            4 "Drop Database" \
            5 "Exit")

        case "$choice" in
        1) createDatabase ;;
        2) listDatabases ;;
        3) connectToDatabase ;;
        4) dropDatabase ;;
        5 | "") exit 0 ;;
        *) kdialog --sorry "Invalid Choice" ;;
        esac
    done
}

createDatabase() {
    name=$(kdialog --inputbox "Enter Database Name:")
    name=$(echo "$name" | awk '{$1=$1;print}')

    if [[ -z "$name" || ! "$name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        kdialog --sorry "Error: Invalid Database Name. Use only letters, numbers, and underscores."
    elif [[ -d "$name" ]]; then
        kdialog --sorry "Error: Database already exists."
    else
        mkdir "$name"
        kdialog --msgbox "Database '$name' created successfully."
    fi
}

listDatabases() {
    if [ -z "$(ls -d */ 2>/dev/null)" ]; then
        kdialog --sorry "No databases found."
        return
    fi

    ls -d */ 2>/dev/null |
        sed 's#/##' | #removes the "/" from output
        awk '
        BEGIN {print "Your Databases:\n"} 
        {print "\t" NR ": " $1"\n\t-----------------"} 
        END {print "\nTotal Databases: "NR}
        ' >.databaseNames.txt
    kdialog --textbox .databaseNames.txt
}

connectToDatabase() {
    databases=($(ls -d */ 2>/dev/null | sed 's#/##'))

    if [ ${#databases[@]} -eq 0 ]; then
        kdialog --sorry "No databases available to connect."
        return
    fi

    menu_items=()
    index=1

    for db in "${databases[@]}"; do
        menu_items+=("$index" "$db")
        ((index++))
    done

    db_index=$(kdialog --menu "Select a Database to Connect" "${menu_items[@]}")

    if [ -n "$db_index" ]; then
        selected_db="${databases[$((db_index - 1))]}"
        kdialog --msgbox "Successfully connected to database: $selected_db"
        tableMenu "$selected_db"
        cd "$HOME/databases"
    fi
}

mainMenu
