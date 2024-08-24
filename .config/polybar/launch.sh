#!/usr/bin/env bash

# Terminate already running bar instances
polybar-msg cmd quit

# Launch the 'example' bar
echo "---" | tee -a /tmp/polybar-example.log
polybar example 2>&1 | tee -a /tmp/polybar-example.log & disown

echo "Polybar example launched..."

