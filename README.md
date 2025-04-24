# ITI Bash DBMS

A fully functional Database Management System implemented entirely in Bash shell scripting, created in February 2025.

## Project Overview

ITI Bash DBMS is a terminal-launched application with a graphical interface built using Bash shell scripts and KDialog. While launched from the command line, it provides a complete graphical menu-driven database management system. The system demonstrates the power of shell scripting for creating practical applications with data storage, manipulation, and retrieval capabilities.

## Authors

- [NourEldin Nabil](https://github.com/NourElDin023)
- [Mohamed Emary](https://github.com/MohamedEmary)

## Features

### Database Management
- Create new databases
- List existing databases
- Connect to databases
- Drop (delete) databases

### Table Management
- Create tables with custom columns and data types
- Define primary key constraints
- List tables in a database
- Drop tables

### Data Operations
- **Insert:** Add new records to tables with data validation
- **Select:** Query data with options to:
  - View all records
  - Search for specific values
- **Update:** Modify existing records with validation
- **Delete:** Remove records by:
  - Primary key
  - Search value

### Data Types & Validation
- Integer data type with validation
- String data type with validation
- Primary key constraints (uniqueness)
- NULL value handling

## Technical Implementation

- **Data Storage:** All data is stored on disk in plain text files
- **Database Structure:**
  - Databases are represented as directories
  - Tables are stored as .table files (data) and .meta files (structure)
  - Table metadata includes column names, data types, and primary key information
- **User Interface:** Implemented using KDialog for a user-friendly graphical menu-driven experience
- **Data Validation:** Type checking and constraints are enforced during data operations

## Usage Instructions

1. Start the application by running `./mainMenu.sh` from the terminal
2. Use the KDialog graphical menus to navigate through database and table operations
3. Follow the prompts to perform specific actions

## Requirements

- Bash Shell
- KDialog (for UI components)
- Linux Operating System

## Project Structure

- `mainMenu.sh` - Entry point and database management functions
- `tableMenu.sh` - Table management and data operation functions
- `README.md` - Documentation

## Installation

### Install KDialog

For Debian/Ubuntu-based systems:
```
sudo apt-get update
sudo apt-get install kdialog
```

For Fedora/RHEL-based systems:
```
sudo dnf install kdialog
```

For Arch Linux:
```
sudo pacman -S kdialog
```

### Running the Application

1. Clone the repository:
    ```
    git clone https://github.com/username/ITI_Bash_DBMS.git
    cd ITI_Bash_DBMS
    ```

2. Make the scripts executable:
    ```
    chmod +x mainMenu.sh tableMenu.sh
    ```

3. Launch the application:
    ```
    ./mainMenu.sh
    ```

## Learning Outcomes

This project demonstrates:
- Advanced Bash scripting techniques
- File system manipulation for data storage
- Command-line interface design
- Data validation and error handling in shell scripts
- Menu-driven application development