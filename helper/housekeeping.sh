yExtendLicense() {
    if [[ ! -d "$CXDEVHOME" ]]; then
        echo -e "${_yerror}[ERROR] CXDEV home must be set before calling yExtendLicense.${_yclear}"
        return 1
    fi
    if [[ ! -d "$CXDEV_PLATFORM_HOME" ]]; then
        echo -e "${_yerror}[ERROR] Platform home must be set before calling yExtendLicense.${_yclear}"
        return 1
    fi

    let CURRENT_DIR=`pwd`
    cd "$CXDEV_PLATFORM_HOME"
    ant executesql -Dsql.file="$CXDEVHOME/sql/extendlicense.sql"
    cd "$CURRENT_DIR"
}

yCompareLoadedExtensions() {
  if [ "$#" -ne 2 ]; then
    echo -e "\033[1;31mUsage:\033[0m yCompareExtensions <logBefore> <logAfter>"
    return 1
  fi

  local LOG_BEFORE="$1"
  local LOG_AFTER="$2"

  if [ ! -f "$LOG_BEFORE" ] || [ ! -f "$LOG_AFTER" ]; then
    echo -e "\033[1;31mError:\033[0m One or both log files do not exist."
    return 1
  fi

  local TMP_BEFORE=$(mktemp)
  local TMP_AFTER=$(mktemp)

  extract_extensions() {
    local logfile="$1"

    grep "\[hybrisserver\]" "$logfile" \
    | sed -E 's/.*\[hybrisserver\] //' \
    | sed -E 's/@deprecated //' \
    | awk '{print $1}' \
    | sed -E 's/(<-?\?-.*|->.*)//' \
    | sed -E 's/\s+//' \
    | sort -u
  }

  extract_extensions "$LOG_BEFORE" > "$TMP_BEFORE"
  extract_extensions "$LOG_AFTER" > "$TMP_AFTER"

  local REMOVED=$(comm -23 "$TMP_BEFORE" "$TMP_AFTER")
  local ADDED=$(comm -13 "$TMP_BEFORE" "$TMP_AFTER")

  echo
  echo -e "\033[1;36m========================================\033[0m"
  echo -e "\033[1;36m Extension Comparison Result\033[0m"
  echo -e "\033[1;36m========================================\033[0m"
  echo

  if [ -n "$REMOVED" ]; then
    echo -e "\033[1;31mRemoved Extensions:\033[0m"
    echo "$REMOVED" | sed 's/^/  - /'
  else
    echo -e "\033[1;32mNo Extensions removed.\033[0m"
  fi

  echo

  if [ -n "$ADDED" ]; then
    echo -e "\033[1;32mAdded Extensions:\033[0m"
    echo "$ADDED" | sed 's/^/  + /'
  else
    echo -e "\033[1;33mNo Extensions added.\033[0m"
  fi

  echo

  rm "$TMP_BEFORE" "$TMP_AFTER"
}

yCleanupImpExForExtensions () {
	if [[ "$#" -eq 0 ]]; then
		echo -e "${_yerror}[ERROR] Please provide at least one extension path.${_yclear}"
		return 1
	fi

	local ATTRIBUTES=()
	local JOBS=()

	for EXT_DIR in "$@"; do

		if [[ ! -d "$EXT_DIR" ]]; then
			echo -e "${_ywarn}[WARN] Extension path not found: $EXT_DIR${_yclear}"
			continue
		fi

		local EXT_NAME
		EXT_NAME="$(basename "$EXT_DIR")"

		# --- Scan Dynamic Attributes ---
		while IFS= read -r XML; do

			while IFS=";" read -r TYPE QUALIFIER; do
				ATTRIBUTES+=("$EXT_NAME;$TYPE;$QUALIFIER")
			done < <(

				awk '
				BEGIN {
					currentType=""
					inItem=0
					inAttribute=0
					isDynamic=0
					redeclare=0
					qualifier=""
				}

				/<itemtype / {
					if (match($0, /code="([^"]+)"/, arr)) {
						currentType=arr[1]
						inItem=1
					}
				}

				/<\/itemtype>/ { inItem=0 }

				inItem && /<attribute / {
					inAttribute=1
					isDynamic=0
					redeclare=0
					qualifier=""

					if (match($0, /qualifier="([^"]+)"/, arr))
						qualifier=arr[1]

					if ($0 ~ /redeclare="true"/)
						redeclare=1
				}

				inAttribute && /type="dynamic"/ {
					isDynamic=1
				}

				/<\/attribute>/ {
					if (inAttribute && isDynamic && redeclare==0 && qualifier != "" && currentType != "") {
						print currentType ";" qualifier
					}
					inAttribute=0
				}
				' "$XML"

			)

		done < <(find "$EXT_DIR" -type f -name "*-items.xml")

		# --- Scan Jobs ---
		while IFS= read -r FILE; do
			if grep -qE "implements[[:space:]]+JobPerformable|extends[[:space:]]+AbstractJobPerformable" "$FILE"; then
				local CLASSNAME
				CLASSNAME="$(basename "$FILE" .java)"
				JOBS+=("$EXT_NAME;$CLASSNAME")
			fi
		done < <(find "$EXT_DIR" -type f \( -name "*Job.java" -o -name "*JobPerformable.java" \))

	done

	# --- Deduplicate ---
	mapfile -t ATTRIBUTES < <(printf "%s\n" "${ATTRIBUTES[@]}" | sort -u)
	mapfile -t JOBS < <(printf "%s\n" "${JOBS[@]}" | sort -u)

	# --- Output ---
	echo
	echo "REMOVE AttributeDescriptor; extensionName; enclosingType(code)[unique = true]; qualifier[unique = true]"
	for LINE in "${ATTRIBUTES[@]}"; do
		echo "$LINE"
	done

	echo
	echo "REMOVE ServiceLayerJob; extensionName; code[unique=true]"
	for LINE in "${JOBS[@]}"; do
		echo "$LINE"
	done

	echo
	echo -e "${_yinfo}[INFO] Cleanup ImpEx generated.${_yclear}"
}

