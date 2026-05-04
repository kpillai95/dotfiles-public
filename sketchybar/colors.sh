#!/bin/bash

export WHITE=0xffffffff

# -- Liquid Glass Neutral Theme --
# Mostly transparent with neutral colors and glass effect
export BAR_COLOR=0x00000000
export ITEM_BG_COLOR=0x40ffffff
export ACCENT_COLOR=0xffe0e0e0
# Space widget colors (plugins/aerospace_space_item.sh inlines these for speed — update both if you change them)
# OLD VALUES (to revert, uncomment these and comment the new values below):
export SPACE_BG_COLOR=0xffffffff
export CURRENT_SPACE_BG=0xff8b0000
export CURRENT_SPACE_TEXT=0xffffffff
# export CURRENT_SPACE_TEXT_LIGHT=0xffcc3333
# export SPACE_TEXT_COLOR=0xffe0e0e0  # Non-selected space text (was ACCENT_COLOR)

# NEW VALUES (selected space: #48FF9C bg, #021524 t;ext; non-selected: #37B6B4 bg, #021524 text):
# export SPACE_BG_COLOR=0xff021254      # Non-selected space background: #37B6B4
# export CURRENT_SPACE_BG=0xff2CFBEA    # Selected space background: #48FF9C
# export CURRENT_SPACE_TEXT=0xff021524  # Selected space text: #021524
# export CURRENT_SPACE_TEXT_LIGHT=0xffcc3333
export SPACE_TEXT_COLOR=0xff000000
export BATTERY_HIGH=0x8040ff40
export BATTERY_MEDIUM=0x80ffff40
export BATTERY_LOW=0x80ff8040
export BATTERY_CRITICAL=0x80800000
# export ORANGE_COLOR=0xfffff700
export ORANGE_COLOR=0xfffff700
# Temperature colors
export TEMP_COLD=0xff4A90E2        # Blue for < 20°C
export TEMP_HOT=0x80DEA246         # Orange/gold (#DEA246) for > 30°C
export TEMP_VERY_HOT=0x80800000    # Dark red for > 40°C (same as BATTERY_CRITICAL)
# CPU colors
export CPU_HIGH=0x80DEA246         # Orange/gold (#DEA246) for > 30%
export CPU_CRITICAL=0x80800000     # Dark red for > 50%
# Memory/Disk colors
export MEMORY_LOW=0x80800000       # Dark red for < 45 GB
# Spark email colors
export SPARK_UNREAD=0x801471FE      # Blue (#1471FE) for unread emails
# Todoist colors
export TODOIST_UNREAD=0x80EE4E39    # Red/orange (#EE4E39) for unread tasks
# Beeper colors
export BEEPER_UNREAD=0x80FD2C4A

# -- Gray Scheme --
# export BAR_COLOR=0xff101314
# export ITEM_BG_COLOR=0xff353c3f
# export ACCENT_COLOR=0xffffffff

# -- Purple Scheme --
# export BAR_COLOR=0xff140c42
# export ITEM_BG_COLOR=0xff2b1c84
# export ACCENT_COLOR=0xffeb46f9

# -- Red Scheme ---
# export BAR_COLOR=0xff23090e
# export ITEM_BG_COLOR=0xff591221
# export ACCENT_COLOR=0xffff2453

# -- Blue Scheme ---
# export BAR_COLOR=0xff021254
# export ITEM_BG_COLOR=0xff093aa8
# export ACCENT_COLOR=0xff15bdf9

# -- Green Scheme --
# export BAR_COLOR=0xff003315
# export ITEM_BG_COLOR=0xff008c39
# export ACCENT_COLOR=0xff1dfca1


# -- Orange Scheme --
# export BAR_COLOR=0xff381c02
# export ITEM_BG_COLOR=0xff99440a
# export ACCENT_COLOR=0xfff97716

# -- Yellow Scheme --
# export BAR_COLOR=0xff2d2b02
# export ITEM_BG_COLOR=0xff8e7e0a
# export ACCENT_COLOR=0xfff7fc17