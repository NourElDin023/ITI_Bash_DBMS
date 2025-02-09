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
            9 "Exit Program" --default "Create Table")

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
        while true; do
            col_name=$(kdialog --inputbox "Enter name for column $i:")
            [[ $? -ne 0 ]] && return

            col_name=$(echo "$col_name" | awk '{$1=$1;print}')

            # Check if column name is valid
            if [[ ! "$col_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
                kdialog --sorry "Error: Column name can only contain letters, numbers, and underscores."
                continue
            fi

            # Check if column name is unique
            if [[ " ${cols[*]} " =~ " $col_name " ]]; then
                kdialog --sorry "Error: Column '$col_name' already exists. Choose another name."
                continue
            fi

            break
        done

        cols+=("$col_name") # Store column name

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

    if [[ -z "$pk_column" ]]; then
        kdialog --sorry "Error: You must select at least one column as the Primary Key."
        return
    fi

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
    checkIfTableExists "$db_name"
    [ -z "$tables" ] && return
    echo "$tables" | awk '
    BEGIN {print "Tables in '"$db_name"':\n"} 
    {print "\t" NR ": " $1 "\n\t-----------------"} 
    END {print "\nTotal Tables: " NR}
    ' >.tableNames.txt

    kdialog --textbox .tableNames.txt 280 320
    rm .tableNames.txt
}

dropTable() {
    checkIfTableExists "$db_name"
    table_menu=()
    index=1
    for table in $tables; do
        table_menu+=("$index" "$table")
        ((index++))
    done

    table_choice=$(kdialog --menu "Select a Table to Drop" "${table_menu[@]}")

    if [ -n "$table_choice" ]; then
        selected_table="$(echo "$tables" | sed -n "${table_choice}p")"
        if kdialog --yesno "Are you sure you want to delete '$selected_table'?"; then
            rm "$table_dir/$selected_table.table"
            rm "$table_dir/$selected_table.meta"
            kdialog --msgbox "Table '$selected_table' deleted successfully."
        fi
    fi
}

insertIntoTable() {
    checkIfTableExists "$db_name"

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

selectFromTable() {
    checkIfTableExists "$db_name"

    # Create table selection menu
    table_menu=()
    index=1
    for table in $tables; do
        table_menu+=("$index" "$table")
        ((index++))
    done

    table_choice=$(kdialog --menu "Select a table to query:" "${table_menu[@]}")

    if [ -z "$table_choice" ]; then
        return
    fi

    selected_table="$(echo "$tables" | sed -n "${table_choice}p")"
    table_file="$table_dir/$selected_table.table"
    metadata_file="$table_dir/$selected_table.meta"

    # Show select options menu
    select_choice=$(kdialog --menu "Select Query Type" \
        1 "Show all records" \
        2 "Find a value")

    case "$select_choice" in
    1)
        # Display all records with proper formatting
        if [ ! -s "$table_file" ]; then
            kdialog --sorry "Table '$selected_table' is empty."
            return
        fi

        # Get column names from metadata
        IFS='|' read -ra metadata_array <"$metadata_file"
        header="<pre>\n"
        separator="--------------------\n"

        # Build header from metadata
        for meta in "${metadata_array[@]}"; do
            col_name="${meta%%:*}"
            header+="$col_name\t"
        done
        header+="\n$separator"

        # Prepare data
        content=$(cat "$table_file" | sed 's/|/\t/g')

        # Show formatted output
        echo -e "${header}${content}\n" >".table_data.txt"
        kdialog --textbox ".table_data.txt" 500 400
        rm ".table_data.txt"
        ;;

    2)
        # Get search value from user
        search_value=$(kdialog --inputbox "Enter search value:")
        if [ $? -ne 0 ]; then
            return
        fi

        # Get column names from metadata for header
        IFS='|' read -ra metadata_array <"$metadata_file"
        header="<pre>\n"
        separator="--------------------\n"

        # Build header from metadata
        for meta in "${metadata_array[@]}"; do
            col_name="${meta%%:*}"
            header+="$col_name\t"
        done
        header+="\n$separator"

        # Search in file and format results
        search_result=$(grep -i "$search_value" "$table_file" | sed 's#|#\t#g')

        if [ -z "$search_result" ]; then
            kdialog --sorry "No records found matching '$search_value'"
        else
            # Show formatted output with header
            echo -e "${header}${search_result}\n" >".search_results.txt"
            kdialog --textbox ".search_results.txt" 500 400
            rm ".search_results.txt"
        fi
        ;;

    *)
        return
        ;;
    esac
}

deleteFromTable() {
    checkIfTableExists "$db_name"

    # Create table selection menu
    table_menu=()
    index=1
    for table in $tables; do
        table_menu+=("$index" "$table")
        ((index++))
    done

    table_choice=$(kdialog --menu "Select a table to delete from:" "${table_menu[@]}")
    [ -z "$table_choice" ] && return

    selected_table="$(echo "$tables" | sed -n "${table_choice}p")"
    table_file="$table_dir/$selected_table.table"
    metadata_file="$table_dir/$selected_table.meta"

    # Check if table is empty
    if [ ! -s "$table_file" ]; then
        kdialog --sorry "Table '$selected_table' is empty."
        return
    fi

    # Get delete method choice
    delete_choice=$(kdialog --menu "Select Delete Method:" \
        1 "Delete by Primary Key" \
        2 "Delete by Search Value")
    [ -z "$delete_choice" ] && return

    case "$delete_choice" in

    1)
        # Delete by Primary Key
        # Find primary key column name and index
        pk_col=""
        pk_index=0
        IFS='|' read -ra metadata_array <"$metadata_file"
        for i in "${!metadata_array[@]}"; do
            IFS=':' read -r col_name _ is_pk <<<"${metadata_array[$i]}"
            if [ "$is_pk" == "PK" ]; then
                pk_col="$col_name"
                pk_index=$i
                break
            fi
        done

        if [ -z "$pk_col" ]; then
            kdialog --sorry "No primary key found in table '$selected_table'."
            return
        fi

        # Get PK value from user
        pk_value=$(kdialog --inputbox "Enter Primary Key value to delete:")
        [ $? -ne 0 ] && return

        # Create temporary file
        temp_file=$(mktemp)
        deleted=false

        # Search and delete matching row
        while IFS='|' read -r line || [ -n "$line" ]; do
            row_pk=$(echo "$line" | cut -d'|' -f$((pk_index + 1)))
            if [ "$row_pk" != "$pk_value" ]; then
                echo "$line" >>"$temp_file"
            else
                deleted=true
            fi
        done <"$table_file"

        if [ "$deleted" = true ]; then
            mv "$temp_file" "$table_file"
            kdialog --msgbox "Record with Primary Key '$pk_value' deleted successfully."
        else
            rm "$temp_file"
            kdialog --sorry "No record found with Primary Key '$pk_value'."
        fi
        ;;

    2)
        # Delete by Search Value
        search_value=$(kdialog --inputbox "Enter value to search and delete:")
        [ $? -ne 0 ] && return

        # Create temporary file
        temp_file=$(mktemp)
        deleted=false

        # Search and delete matching rows
        while IFS= read -r line || [ -n "$line" ]; do
            if ! echo "$line" | grep -qi "$search_value"; then
                echo "$line" >>"$temp_file"
            else
                deleted=true
            fi
        done <"$table_file"

        if [ "$deleted" = true ]; then
            mv "$temp_file" "$table_file"
            kdialog --msgbox "Records containing '$search_value' deleted successfully."
        else
            rm "$temp_file"
            kdialog --sorry "No records found containing '$search_value'."
        fi
        ;;

    *)
        return
        ;;
    esac
}
