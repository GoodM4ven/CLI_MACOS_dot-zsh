#!/bin/bash
page_size="$(pagesize 2>/dev/null || echo 4096)"
total_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
used_pages="$(vm_stat 2>/dev/null | awk '/Pages active/ {gsub(/\./,"",$3);a=$3} /Pages wired down/ {gsub(/\./,"",$4);w=$4} /Pages occupied by compressor/ {gsub(/\./,"",$5);c=$5} END {printf "%.0f",a+w+c}')"
if [[ "$total_bytes" -gt 0 && -n "$used_pages" ]]; then
  p=$((used_pages * page_size * 100 / total_bytes)); ((p>100)) && p=100
else
  p="--"
fi
sketchybar --set ram label="${p}%"
