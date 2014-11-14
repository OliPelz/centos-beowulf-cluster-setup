#!/bin/bash

# this script returns extracting tool and possible flags for a given (parameter) filename
# this script defines three environment variables therefore it can be super easy used in other scripts using the source command
# written by oliverpelz@googlemail.com
# e.g. in a "master" script doing:
# source extractor.sh "myLittleArchive.tar.gz"
# would make the following four environment variables available in the "master" script for further use:
# extract_tool
# extract_flag
# extract_to_flag
# extract_list_flag

# for further we would than in the "master" script do something like to show the package content
# `"$extract_tool $extract_list_flag $temp_dir/$filename"`
# or to extract
# `"$extract_tool $extract_flag $temp_dir/$filename"`
# etc.


if [ -f "$1" ]
then
  case "$filename" in
     *.tar.bz2) extract_tool="tar --strip-components=1";extract_flag="-xvf";extract_to_flag="-C";extract_list_flag="-tvf" ;;
     *.bz2)     extract_tool="bzip2";extract_flag="-ckd";extract_to_flag="-C";extract_list_flag="-l" ;;
     *.tar.gz)  extract_tool="tar --strip-components=1";extract_flag="-xvf";extract_to_flag="-C";extract_list_flag="-tvf" ;;
     *.tgz)     extract_tool="tar --strip-components=1";extract_flag="-xvf";extract_to_flag="-C";extract_list_flag="-jtvf" ;;
     *.gz)      extract_tool="gunzip";extract_flag="-c";extract_to_flag="-C";extract_list_flag="-l" ;;
     *.zip)     extract_tool="unzip";extract_flag="-c";extract_to_flag="-C";extract_list_flag="-l" ;;
     *.rar)     extract_tool="unrar";extract_flag="x";extract_to_flag="-ad";extract_list_flag="-l" ;;
     *.7z)      echo "downloaded file extension not implemented yet" ;;
     *)         echo "downloaded file extension not implemented yet" ;;
  esac
else
  echo "'$1' - filename does not exist"
fi
