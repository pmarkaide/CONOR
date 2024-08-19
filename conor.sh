#!/usr/bin/bash

# Needed software
PACKAGE_NAME="c-formatter-42"

# Directory and file lists
INCLUDE_DIRS=("src" "include")

# URL of the raw conor.sh file on GitHub
GITHUB_URL="https://raw.githubusercontent.com/pmarkaide/CONOR_correct_norminette/main/conor.sh"

# Determine the script's directory and path
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Fetch the latest version of the conor.sh file from GitHub
LATEST_FILE=$(mktemp)
curl -s -o "$LATEST_FILE" "$GITHUB_URL"

# Compare the fetched file with the local version
if ! cmp -s "$SCRIPT_PATH" "$LATEST_FILE"; then
    echo "There is an updated version of conor.sh available."
    read -p "Do you want to update to the latest version? (y/n): " choice
    if [ "$choice" = "y" ]; then
        cp "$LATEST_FILE" "$SCRIPT_PATH"
        echo "conor.sh has been updated. Please re-run the script."
        exit 0
    fi
fi

# Install c-formatter-42 if needed
if ! pip3 show "$PACKAGE_NAME" > /dev/null 2>&1; then
    echo "Package $PACKAGE_NAME is not installed. Installing..."
    pip3 install --user "$PACKAGE_NAME"
fi

# Check and add newline at the end of files if missing
for dir in "${INCLUDE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        for file in $(find "$dir" -type f \( -name "*.c" -or -name "*.h" \)); do
            if [ -n "$(tail -c 1 "$file")" ]; then
                echo >> "$file"
                echo "[INFO] Added newline to $file"
            fi
        done
    else
        echo "[ERROR] Directory $dir does not exist."
    fi
done

# Correct norminette errors and track fixed files
FIXED_FILES=()

for dir in "${INCLUDE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        for file in $(find "$dir" -type f \( -name "*.c" -or -name "*.h" \)); do
            tmp_file=$(mktemp)
            cp "$file" "$tmp_file"
            python3 -m c_formatter_42 "$file" 1>/dev/null
            # Compare the formatted file with the original file
            if ! cmp -s "$file" "$tmp_file"; then
                FIXED_FILES+=("$file")
            fi
            rm "$tmp_file"
        done
    else
        echo "[ERROR] Directory $dir does not exist."
    fi
done

# Print the files that were fixed
if [ ${#FIXED_FILES[@]} -ne 0 ]; then
     for file in "${FIXED_FILES[@]}"; do
        echo "[FIX] $file"
    done
fi

# Run norminette and check for errors
ERROR_FOUND=false

for dir in "${INCLUDE_DIRS[@]}"; do
	if [ -d "$dir" ]; then
		output=$(norminette -R CheckForbiddenSourceHeaders "$dir" 2>&1)
	   	if echo "$output" | grep -E '\.c: Error!|\.h: Error!' > /dev/null; then
			ERROR_FOUND=true
			error_files=$(echo "$output" | grep -E '\.c: Error!|\.h: Error!' | awk -F: '{print $1}')
            ERROR_FILES+=($error_files)
		fi
	else
		echo "[ERROR] Directory $dir does not exist."
	fi
done

# Raise a warning message if errors were found
if $ERROR_FOUND; then
	for file in "${ERROR_FILES[@]}"; do
        echo "[ERROR] $file still has norminette errors"
    	done
	else
		echo "[PASS] Norminette OK for all files"
fi

## TODO
# Point to which files give the error
# Add files to ignore
# Redirect output for silence
