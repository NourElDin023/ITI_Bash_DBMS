tableMenu() {
    db_name="$1"
    cd "$HOME/databases/$db_name"

    while true; do
        choice=$(kdialog --menu "Manage Tables in $db_name" \
            1 "Create Table" \
            2 "List Tables" \
            3 "Drop Table" \
            4 "Insert into Table" \
            5 "Select From Table" \
            6 "Delete From Table" \
            7 "Update Table" \
            8 "Back to Main Menu" \
            9 "Exit Program")

        case "$choice" in
        1) createTable "$db_name" ;;
        2) listTables "$db_name" ;;
        3) dropTable "$db_name" ;;
        4) insertIntoTable "$db_name" ;;
        5) selectFromTable "$db_name" ;;
        6) deleteFromTable "$db_name" ;;
        7) updateTable "$db_name" ;;
        8) break ;;
        9 | "") exit 0 ;;
        *) kdialog --sorry "Invalid Choice" ;;
        esac
    done
    cd "$HOME/databases"
}
