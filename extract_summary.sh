#!/bin/bash

# file="readme.md"
# repo_prefix="https://github.com/dywsun/notes/blob/main"
# truncate -s 0 $file
#
# echo "### 日常小记" >> $file
# echo "" >> $file
#
# # 目录名是以日期取名的，所以这里用ls -r选项把日期大的排在前面
# for dir in $(ls -rd */); do
#   echo "##### $(basename $dir)" >> $file
#   for note in $(ls "$dir" | grep '.md$'); do
#     url="$repo_prefix/$dir$note"
#     echo "* [${note%.md}]($url)" >> $file
#   done
#   echo "" >> $file
# done

repo_prefix="https://github.com/dywsun/notes/blob/main"
declare -A POST_TAGS
DEFAULT_TAG="other"
TAG_FILE="tag.md"
DATE_FILE="readme.md"
TEMP_FILE="/tmp/post_temp"
truncate -s 0 ${TAG_FILE}
truncate -s 0 ${DATE_FILE}
truncate -s 0 ${TEMP_FILE}

index_files=(${DATE_FILE} ${TAG_FILE})

for file in ${index_files[@]}; do
  echo "### [日期排序]($repo_prefix/$DATE_FILE)" >> ${file}
  echo "### [标签分类]($repo_prefix/$TAG_FILE)" >> ${file}
  echo "---" >> ${file}
done

# sort for tag
for mdfile in $(ls post); do
  # echo "${mdfile}"
  tags=$(sed -n '/:pushpin: tag:/p' "post/$mdfile" | awk '{for(i=4;i<=NF;i++) printf "%s%s", $i, (i<NF?OFS:ORS)}')
  if [ -z "${tags}" ]; then
    POST_TAGS["$DEFAULT_TAG"]+="$mdfile"
  fi
  IFS=' ' read -r -a tt <<< "$tags"
  for tag in "${tt[@]}"; do
    POST_TAGS[$tag]+="$mdfile "
  done

  date=$(sed -n '/:calendar: date:/p' "post/$mdfile" | awk '{print $4}')
  if [ -z "$date" ]; then
    echo "$mdfile" >> ${TEMP_FILE}
  else
    echo "$date $mdfile" >> ${TEMP_FILE}
  fi
done

sort -k1,1r ${TEMP_FILE} | awk -v repo="$repo_prefix" '{
  print "* ["$0"]("repo"/post/"$NF")"
}' >> ${DATE_FILE}

for TAG in "${!POST_TAGS[@]}"; do
  echo "#### ${TAG}" >> ${TAG_FILE}
  for mdfile in ${POST_TAGS[$TAG]}; do
    echo "* [${mdfile%.md}]($repo_prefix/post/$mdfile)" >> ${TAG_FILE}
  done
  echo "" >> ${TAG_FILE}
done

