tableMenu() {
    db_name="$1"

    while true; do
        choice=$(kdialog --title "Database: $db_name" --menu "Manage Tables in $db_name" \
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

createTable() {
    db_name="$1"

    table_name=$(kdialog --inputbox "Enter Table Name:")
    [[ $? -ne 0 ]] && return

    table_name=$(echo "$table_name" | awk '{$1=$1;print}')

    if [[ ! "$table_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        kdialog --sorry "Error: Table name can only contain letters, numbers, and underscores."
        return
    fi

    if [[ -f "$db_name/$table_name.table" ]]; then
        kdialog --sorry "Error: Table already exists."
        return
    fi

    num_cols=$(kdialog --inputbox "Enter Number of Columns:")
    [[ $? -ne 0 ]] && return

    if ! [[ "$num_cols" =~ ^[1-9][0-9]*$ ]]; then
        kdialog --sorry "Error: Invalid column number."
        return
    fi

    cols=()
    col_defs=()
    pk_column=""

    for ((i = 1; i <= num_cols; i++)); do
        col_name=$(kdialog --inputbox "Enter name for column $i:")
        [[ $? -ne 0 ]] && return

        col_name=$(echo "$col_name" | awk '{$1=$1;print}')
        col_type=$(kdialog --menu "Select data type for $col_name" 1 "int" 2 "string")
        [[ $? -ne 0 ]] && return

        if [[ -z "$pk_column" ]]; then
            kdialog --yesno "Is $col_name the primary key?"
            response=$?

            if [[ $response -eq 0 ]]; then
                pk_column="$col_name"
                col_defs+=("$col_name:$col_type:PK")
            elif [[ $response -eq 1 ]]; then
                col_defs+=("$col_name:$col_type")
            else
                return
            fi
        else
            col_defs+=("$col_name:$col_type")
        fi

    done

    echo "${col_defs[*]}" | tr ' ' '|' >"$db_name/$table_name.meta"
    touch "$db_name/$table_name.table"

    kdialog --msgbox "Table '$table_name' created successfully in database '$db_name'."
}

listTables() {
    db_name="$1"
    table_dir="$HOME/databases/$db_name"
    tables=$(ls "$table_dir"/*.table | sed 's#.*/##' | sed 's#.table##')

    if [ -z "$tables" ]; then
        kdialog --sorry "No tables found in database '$db_name'."
        return
    fi

    echo "$tables" | awk '
    BEGIN {print "Tables in '"$db_name"':\n"} 
    {print "\t" NR ": " $1 "\n\t-----------------"} 
    END {print "\nTotal Tables: " NR}
    ' >.tableNames.txt

    kdialog --textbox .tableNames.txt 280 320
    rm .tableNames.txt
}
