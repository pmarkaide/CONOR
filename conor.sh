#!/usr/bin/bash

# Needed software
PACKAGE_NAME="c-formatter-42"

# Directory and file lists
INCLUDE_DIRS=("src" "include")


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

# Correct norminette errors
for dir in "${INCLUDE_DIRS[@]}"; do
	if [ -d "$dir" ]; then
		find "$dir" -type f \( -name "*.c" -or -name "*.h" \) -exec python3 -m c_formatter_42 {} \; 1>/dev/null
	else
        echo "[ERROR] Directory $dir does not exist."
	fi
done

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
