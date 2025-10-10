#!/bin/bash

file='notes.md'
truncate -s 0 $file

echo "### 日常小记" >> $file
echo "" >> $file

# 目录名是以日期取名的，所以这里用ls -r选项把日期大的排在前面
for dir in $(ls -rd */); do
  echo "##### $(basename $dir)" >> $file
  for note in $(ls "$dir" | grep '.md$'); do
    echo "* ${note%.md}" >> $file
  done
  echo "" >> $file
done

