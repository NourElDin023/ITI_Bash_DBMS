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

checkIfTableExists() {
    db_name="$1"
    table_dir="$HOME/databases/$db_name"
    tables=$(ls "$table_dir"/*.table | sed 's#.*/##' | sed 's#.table##')

    if [ -z "$tables" ]; then
        kdialog --sorry "No tables found in database '$db_name'."
        return
    fi
}

listTables() {
    checkIfTableExists

    echo "$tables" | awk '
    BEGIN {print "Tables in '"$db_name"':\n"} 
    {print "\t" NR ": " $1 "\n\t-----------------"} 
    END {print "\nTotal Tables: " NR}
    ' >.tableNames.txt

    kdialog --textbox .tableNames.txt 280 320
    rm .tableNames.txt
}

dropTable() {
    checkIfTableExists
    table_menu=()
    index=1
    for table in $tables; do
        table_menu+=("$index" "$table")
        ((index++))
    done

    table_choice=$(kdialog --menu "Select a Table to Drop" "${table_menu[@]}")

    if [ -n "$table_choice" ]; then
        selected_table="${table_menu[((table_choice * 2 - 1))]}"
        if kdialog --yesno "Are you sure you want to delete '$selected_table'?"; then
            rm "$table_dir/$selected_table.table"
            rm "$table_dir/$selected_table.meta"
            kdialog --msgbox "Table '$selected_table' deleted successfully."
        fi
    fi
}

insertIntoTable() {
    checkIfTableExists

    table_menu=()
    index=1
    for table in $tables; do
        table_menu+=("$index" "$table")
        ((index++))
    done

    table_choice=$(kdialog --menu "Select a table to insert data into:" "${table_menu[@]}")

    if [ -z "$table_choice" ]; then
        return
    fi

    selected_table="$(echo "$tables" | sed -n "${table_choice}p")"

    metadata_file="$table_dir/$selected_table.meta"
    table_file="$table_dir/$selected_table.table"

    if [ ! -f "$metadata_file" ]; then
        kdialog --sorry "Metadata file not found for table '$selected_table'."
        return
    fi

    # Read column names and types
    columns=()
    col_types=()
    col_defs=()
    pk_index=-1 # Track the index of the Primary Key column

    IFS='|' read -ra metadata_array <"$metadata_file"

    for i in "${!metadata_array[@]}"; do
        IFS=':' read -r col_name col_type is_pk <<<"${metadata_array[$i]}"
        if [ -n "$col_name" ]; then
            columns+=("$col_name")
            col_types+=("$col_type")
            col_defs+=("$col_name:$col_type:$is_pk")

            if [ "$is_pk" == "PK" ]; then
                pk_index=$i
            fi
        fi
    done

    if [ ${#columns[@]} -eq 0 ]; then
        kdialog --sorry "No columns found in metadata."
        return
    fi

    # Collect user input for each column
    row_data=()
    for i in "${!columns[@]}"; do
        col_name="${columns[$i]}"
        col_type="${col_types[$i]}"
        is_pk="${col_defs[$i]##*:}"

        # Inside insertIntoTable() function, modify the hint message:
        while true; do
            # Add user instruction to input dialog with data type
            hint="Enter value for $col_name"

            # Add data type info
            if [ "$col_type" == "1" ]; then
                hint+="\n[Type: Integer]"
            elif [ "$col_type" == "2" ]; then
                hint+="\n[Type: String]"
            fi

            # Add PK or NULL info
            if [ "$is_pk" == "PK" ]; then
                hint+="\n[Primary Key - Must be Unique && Not Empty]"
            else
                hint+="\n(Leave empty and press Enter for NULL)"
            fi

            value=$(kdialog --inputbox "$hint")

            # **Handle Cancel or ESC Pressed**
            if [ $? -ne 0 ]; then
                return # Exit the function if user cancels
            fi

            # **Only Primary Key Can't Be Empty**
            if [ -z "$value" ] && [ "$is_pk" == "PK" ]; then
                kdialog --sorry "Error: Primary Key '$col_name' cannot be empty."
                continue
            elif [ -z "$value" ]; then
                row_data+=("NULL") # Store NULL for optional fields
                break
            fi

            # Validate integer fields (col_type == "1" means it's an integer)
            if [[ "$col_type" == "1" && ! "$value" =~ ^[0-9]+$ ]]; then
                kdialog --sorry "Invalid input for $col_name. Expected an integer."
                continue
            fi

            # Validate string fields (col_type == "2" means it's a string)
            if [[ "$col_type" == "2" && ! "$value" =~ ^[a-zA-Z0-9_[:space:]]+$ ]]; then
                kdialog --sorry "Invalid input for $col_name. Only letters, numbers, spaces, and underscores allowed."
                continue
            fi

            # **Check PK Uniqueness**
            if [ "$is_pk" == "PK" ]; then
                if grep -q "^$value|" "$table_file" 2>/dev/null; then
                    kdialog --sorry "Error: Primary key '$value' already exists in table '$selected_table'."
                    continue
                fi
            fi

            row_data+=("$value")
            break
        done
    done

    # Insert data into table (separating values with '|')
    echo "${row_data[*]}" | sed 's/ /|/g' >>"$table_file"

    kdialog --msgbox "Data inserted successfully into '$selected_table'."
}
