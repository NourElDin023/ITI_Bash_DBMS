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

mainMenu
