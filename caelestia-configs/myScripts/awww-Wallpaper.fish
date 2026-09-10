#!/usr/bin/env fish

# 1. Start the daemon if it isn't running
if not pgrep -x awww-daemon >/dev/null
    awww-daemon --no-cache &
    sleep 0.2
end

# 2. Define your favorite transition types here (separated by spaces)
set MY_FAVORITE_ANIMATIONS wave wipe grow center outer left right top bottom

# 3. Randomly select one animation from your list
set CHOSEN_ANIMATION (string split " " $MY_FAVORITE_ANIMATIONS | shuf -n 1)

# 4. Define wallpaper directory and grab a file
set WALLPAPER_DIR "$HOME/Pictures/Wallpapers"
set RANDOM_WALLPAPER (find "$WALLPAPER_DIR" -type f | shuf -n 1)

# 5. Apply the wallpaper using the dynamically chosen animation
if string length -q "$RANDOM_WALLPAPER"
    awww img --transition-type $CHOSEN_ANIMATION --transition-step 255 --transition-fps 60 "$RANDOM_WALLPAPER" >/dev/null 2>&1
else
    echo "Error: No files found in $WALLPAPER_DIR"
end
