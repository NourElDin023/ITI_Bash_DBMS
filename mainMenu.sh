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
            5 "Exit" \
            --default "Create Database")

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
    if [ -z "$(ls -d */)" ]; then
        kdialog --sorry "No databases found."
        return
    fi

    ls -d */ |
        sed 's#/##' | #removes the "/" from output
        awk '
        BEGIN {print "Your Databases:\n"} 
        {print "\t" NR ": " $1"\n\t-----------------"} 
        END {print "\nTotal Databases: "NR}
        ' >.databaseNames.txt
    kdialog --textbox .databaseNames.txt 280 320
}

connectToDatabase() {
    databases=($(ls -d */ | sed 's#/##'))

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

dropDatabase() {
    databases=($(ls -d */ | sed 's#/##'))
    if [ ${#databases[@]} -eq 0 ]; then
        kdialog --sorry "No databases to delete."
        return
    fi

    menu_items=()
    index=1

    for db in "${databases[@]}"; do
        menu_items+=("$index" "$db")
        ((index++))
    done

    db_index=$(kdialog --menu "Select a Database to Drop" "${menu_items[@]}")

    if [ -n "$db_index" ]; then
        selected_db="${databases[$((db_index - 1))]}"

        if kdialog --yesno "Are you sure you want to delete '$selected_db'?"; then
            rm -r "$selected_db"
            kdialog --msgbox "Database '$selected_db' deleted successfully."
        fi
    fi
}

mainMenu
