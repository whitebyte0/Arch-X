#!/bin/bash
# lib.sh — shared helpers for waybar info popups

GREEN='#a6e3a1'
YELLOW='#f9e2af'
BLUE='#89b4fa'
PINK='#f38ba8'
DIM='#6c7086'

sanitize() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
section() { echo "<span color='${1}'><b>$2</b></span>"; }
