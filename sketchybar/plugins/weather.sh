#!/usr/bin/env bash

# Set CONFIG_DIR if not set (when called from sketchybar)
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/plugins/env.sh"
source "$CONFIG_DIR/colors.sh"

# False = night
# True = daytime
weather_icon_map() {
	shopt -s extglob
	# Convert to lowercase for case-insensitive matching and remove extra whitespace
	forecast_lower=$(echo "$2" | tr '[:upper:]' '[:lower:]' | sed 's/  */ /g' | xargs)
	
	# Ensure we have a valid forecast string
	if [ -z "$forecast_lower" ] || [ "$forecast_lower" = "null" ] || [ "$forecast_lower" = "" ]; then
		if [ "$1" = "true" ]; then
			echo "􀆭"
		else
			echo "􀆮"
		fi
		return
	fi
	
	# check if first argument is true or false to determine whether day or night
	# Order matters: more specific patterns first, then general ones
	if [ "$1" = "true" ]; then # Daytime
		case $forecast_lower in
		# Severe weather first
		*thunder* | *storm* | *lightning*)
			icon_result="􀇞"
			;;
		# Precipitation
		*snow* | *sleet* | *blizzard*)
			icon_result="􀇍"
			;;
		*rain* | *shower* | *drizzle* | *precipitation*)
			icon_result="􀇄"
			;;
		# Partly conditions (more specific)
		*"partly sunny"* | *"partly clear"*)
			icon_result="􀇔"
			;;
		*"partly cloudy"* | *"partly"*)
			icon_result="􀇔"
			;;
		# Clear/sunny conditions
		*sunny* | *clear* | *sun* | *fair*)
			icon_result="􀆭"
			;;
		# Cloudy conditions
		*cloudy* | *overcast* | *cloud* | *mostly*cloudy*)
			icon_result="􀇂"
			;;
		# Fog/mist
		*fog* | *mist* | *haze* | *smoke*)
			icon_result="􀇊"
			;;
		# Wind
		*windy* | *breezy*)
			if [ "$1" = "true" ]; then
				icon_result="􀇤"
			else
				icon_result="􀇬"
			fi
			;;
		# Default to sunny for daytime
		*)
			icon_result="􀆭"
			;;
		esac
	else
		# Night time
		case $forecast_lower in
		# Severe weather first
		*thunder* | *storm* | *lightning*)
			icon_result="􀼱"
			;;
		# Precipitation
		*snow* | *sleet* | *blizzard*)
			icon_result="􀼮"
			;;
		*rain* | *shower* | *drizzle* | *precipitation*)
			icon_result="􀼯"
			;;
		# Clear night
		*clear* | *sunny* | *fair*)
			icon_result="􀆮"
			;;
		# Cloudy/partly cloudy
		*cloudy* | *overcast* | *cloud* | *"partly"* | *mostly*cloudy*)
			icon_result="􀼬"
			;;
		# Fog/mist
		*fog* | *mist* | *haze* | *smoke*)
			icon_result="􀼰"
			;;
		# Default to moon for night
		*)
			icon_result="􀆮"
			;;
		esac
	fi
	
	# Ensure we always return a valid icon
	if [ -z "$icon_result" ] || [ "$icon_result" = "" ]; then
		if [ "$1" = "true" ]; then
			icon_result="􀆭"
		else
			icon_result="􀆮"
		fi
	fi
	
	echo "$icon_result"
}

render_bar() {
	# Set both icon and temperature in the same item
	# If icon is missing or unclear, use a default sun/moon icon based on time
	if [ -n "$temp" ]; then
		if [ -z "$icon" ] || [ "$icon" = "" ]; then
			# Use default sun/moon icon if weather condition icon is unavailable
			# Determine time of day for default icon
			hour=$(date +%H)
			if [ "$hour" -ge 6 ] && [ "$hour" -lt 20 ]; then
				icon="􀆭"  # Sun for daytime
			else
				icon="􀆮"  # Moon for nighttime
			fi
		fi
		
		# Set color based on temperature
		# Convert temp to numeric value for comparison (handles decimals and negatives)
		temp_float=$(echo "$temp" | grep -oE '^-?[0-9]+\.?[0-9]*' | head -1)
		
		# Determine color based on temperature using bc for floating point comparison
		if [ -n "$temp_float" ]; then
			# Less than 20°C: blue
			if [ "$(echo "$temp_float < 20" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
				TEMP_COLOR=$TEMP_COLD
			# Above 40°C: dark red
			elif [ "$(echo "$temp_float > 40" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
				TEMP_COLOR=$TEMP_VERY_HOT
			# Above 30°C: orange/red
			elif [ "$(echo "$temp_float > 30" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
				TEMP_COLOR=$TEMP_HOT
			else
				# 20-30°C: default background color (normal range)
				TEMP_COLOR=$ITEM_BG_COLOR
			fi
		else
			TEMP_COLOR=$ITEM_BG_COLOR
		fi
		
		sketchybar --set weather icon="$icon" icon.drawing=on label="$temp""°" background.color="$TEMP_COLOR" background.drawing=on drawing=on
	else
		sketchybar --set weather icon="" icon.drawing=off label="?" drawing=on
	fi
}

render_popup() {
	sketchybar --remove '/weather.details.\.*/'

	weather_details=(
		label="$forecast $popup_weather"
		label.padding_left=80
		click_script="sketchybar --set $NAME popup.drawing=off"
		position=popup.weather
		drawing=on
	)

	COUNTER=0

	sketchybar --clone weather.details."$COUNTER" weather.details
	sketchybar --set weather.details."$COUNTER" "${weather_details[@]}"

	echo "$weather" | jq -r '.properties.periods[] | @base64' | while read -r period; do
		COUNTER=$((COUNTER + 1))

		if [ "$COUNTER" -lt 4 ]; then
			decoded_period=$(echo "$period" | base64 --decode)
			period_name=$(echo "$period" | base64 --decode | jq -r '.name')
			detailed_forecast=$(echo "$decoded_period" | jq -r '.detailedForecast')
			temperature=$(echo "$decoded_period" | jq -r '.temperature')
			temperature_unit=$(echo "$decoded_period" | jq -r '.temperatureUnit')

			weather_period=(
				icon="$period_name - $temperature $temperature_unit"
				icon.color="$BLUE"
				label="$sentence"
				label.drawing=on
				click_script="sketchybar --set $NAME popup.drawing=off"
				drawing=on
			)

			item=weather.details."$COUNTER"
			sketchybar --add item "$item" popup.weather
			sketchybar --set "$item" "${weather_period[@]}"

			SUBCOUNTER=0
			echo "$detailed_forecast" | grep -o -E '\b[^.!?]*[.!?]' | while read -r sentence; do

				SUBCOUNTER=$((SUBCOUNTER + 1))
				weather_period=(
					label="$sentence"
					label.drawing=on
					click_script="sketchybar --set $NAME popup.drawing=off"
					drawing=on
				)

				item=weather.details."$COUNTER"."$SUBCOUNTER"
				sketchybar --add item "$item" popup.weather
				sketchybar --set "$item" "${weather_period[@]}"
			done

			sketchybar --add item weather.details.newline."$COUNTER" popup.weather
		fi
	done
}

update() {
	# Check if weather_config.json exists
	if [ ! -f ~/weather_config.json ]; then
		sketchybar --set weather icon="" icon.drawing=off label="?" drawing=on
		return
	fi

	# Check if we should use wttr.in for main display (for non-US locations)
	use_wttr=$(jq -r '.use_wttr_for_main' ~/weather_config.json 2>/dev/null)
	
	if [ "$use_wttr" = "true" ]; then
		# Use wttr.in for main display (works globally)
		wttr_location=$(jq -r '.wttr.location' ~/weather_config.json 2>/dev/null)
		wttr_url="https://wttr.in/${wttr_location}?format=j1"
		
		weather=$(curl -s "$wttr_url" 2>/dev/null)
		if [ -z "$weather" ]; then
			sketchybar --set weather icon="" icon.drawing=off label="?" drawing=on
			return
		fi
		
		# Parse wttr.in JSON format
		# Try temp_C first, but also check feelslikeC as fallback
		temp=$(echo "$weather" | jq -r '.current_condition[0].temp_C' 2>/dev/null)
		
		# Validate temperature is reasonable (between -50 and 60 Celsius)
		# If temp is empty, null, or seems wrong, try alternative fields
		if [ -z "$temp" ] || [ "$temp" = "null" ] || [ "$temp" = "" ]; then
			temp=$(echo "$weather" | jq -r '.current_condition[0].feelslikeC' 2>/dev/null)
		fi
		
		# Additional validation: if temp is less than -10 or greater than 50, it's likely wrong
		# Try the weather array which might have more accurate data
		if [ -n "$temp" ] && [ "$temp" != "null" ]; then
			temp_int=$(echo "$temp" | cut -d. -f1)
			if [ "$temp_int" -lt -10 ] || [ "$temp_int" -gt 50 ]; then
				# Temperature seems unreasonable, try alternative source
				temp=$(echo "$weather" | jq -r '.weather[0].mintempC' 2>/dev/null)
				# If that doesn't work, try maxtempC
				if [ -z "$temp" ] || [ "$temp" = "null" ]; then
					temp=$(echo "$weather" | jq -r '.weather[0].maxtempC' 2>/dev/null)
				fi
			fi
		fi
		
		# Try multiple fields to get forecast description (order matters - most descriptive first)
		forecast=$(echo "$weather" | jq -r '.current_condition[0].weatherDesc[0].value' 2>/dev/null)
		
		# If forecast is empty or null, try alternative fields
		if [ -z "$forecast" ] || [ "$forecast" = "null" ] || [ "$forecast" = "" ]; then
			forecast=$(echo "$weather" | jq -r '.current_condition[0].lang_en[0].value' 2>/dev/null)
		fi
		
		# Try condition field
		if [ -z "$forecast" ] || [ "$forecast" = "null" ] || [ "$forecast" = "" ]; then
			forecast=$(echo "$weather" | jq -r '.current_condition[0].condition' 2>/dev/null)
		fi
		
		# Try weather array as last resort
		if [ -z "$forecast" ] || [ "$forecast" = "null" ] || [ "$forecast" = "" ]; then
			forecast=$(echo "$weather" | jq -r '.weather[0].hourly[0].weatherDesc[0].value' 2>/dev/null)
		fi
		
		# Clean up forecast text - remove extra spaces and ensure it's lowercase-friendly
		if [ -n "$forecast" ] && [ "$forecast" != "null" ]; then
			forecast=$(echo "$forecast" | sed 's/  */ /g' | xargs)
		fi
		
		# Determine if daytime - use actual sunrise/sunset from API if available, otherwise estimate
		# wttr.in provides local time, so we can use the hour from the API response
		# For Australia (AEST/AEDT), estimate 6 AM to 8 PM
		hour=$(date +%H)
		if [ "$hour" -ge 6 ] && [ "$hour" -lt 20 ]; then
			time="true"
		else
			time="false"
		fi
		
		# Also check if the API provides is_daytime or similar
		is_day=$(echo "$weather" | jq -r '.current_condition[0].isdaytime' 2>/dev/null)
		if [ "$is_day" = "Yes" ] || [ "$is_day" = "yes" ] || [ "$is_day" = "1" ]; then
			time="true"
		elif [ "$is_day" = "No" ] || [ "$is_day" = "no" ] || [ "$is_day" = "0" ]; then
			time="false"
		fi
		
		# Map weather icon - always call the function, it handles defaults
		icon=$(weather_icon_map "$time" "$forecast")
		
		# Double-check we have a valid icon
		if [ -z "$icon" ] || [ "$icon" = "" ]; then
			if [ "$time" = "true" ]; then
				icon="􀆭"
			else
				icon="􀆮"
			fi
		fi
	else
		# Use weather.gov (US only)
		url=$(jq -r '.weathergov | "\(.url)\(.location)/\(.format)"' ~/weather_config.json 2>/dev/null)
		if [ -z "$url" ] || [ "$url" = "null" ]; then
			sketchybar --set weather icon="" icon.drawing=off label="?" drawing=on
			return
		fi

		weather=$(curl -s "$url" 2>/dev/null)
		if [ -z "$weather" ]; then
			sketchybar --set weather icon="" icon.drawing=off label="?" drawing=on
			return
		fi

		temp=$(echo "$weather" | jq -r '.properties.periods[0].temperature' 2>/dev/null)
		forecast=$(echo "$weather" | jq -r '.properties.periods[0].shortForecast' 2>/dev/null)
		time=$(echo "$weather" | jq -r '.properties.periods[0].isDaytime' 2>/dev/null)
		
		# Clean up forecast text
		if [ -n "$forecast" ] && [ "$forecast" != "null" ]; then
			forecast=$(echo "$forecast" | sed 's/  */ /g' | xargs)
		fi
		
		icon=$(weather_icon_map "$time" "$forecast")
		
		# If icon mapping failed, use default
		if [ -z "$icon" ] || [ "$icon" = "" ]; then
			if [ "$time" = "true" ]; then
				icon="􀆭"
			else
				icon="􀆮"
			fi
		fi
	fi

	# popup
	url=$(jq -r '.wttr | "\(.url)\(.location)?\(.format)"' ~/weather_config.json 2>/dev/null)
	popup_weather=$(curl -s "$url" 2>/dev/null | sed 's/  */ /g')

	render_bar
	render_popup

	if [ "$COUNT" -ne "$PREV_COUNT" ] 2>/dev/null || [ "$SENDER" = "forced" ]; then
		sketchybar --animate tanh 15 --set "$NAME" label.y_offset=5 label.y_offset=0
	fi
}

popup() {
	sketchybar --set "$NAME" popup.drawing="$1"
}

case "$SENDER" in
"routine" | "forced" | "")
	update
	;;
"mouse.entered")
	popup on
	;;
"mouse.exited" | "mouse.exited.global")
	popup off
	;;
"mouse.clicked")
	popup toggle
	;;
esac