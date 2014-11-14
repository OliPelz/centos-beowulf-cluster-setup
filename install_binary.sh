#!/bin/bash

#this script downloads a file locally from any public server
#than copies that file on all nodes in a given list and
#installs the software in a standard directory

#parameters: 1: the nodes you want to install the software to
#            2: the download URL, must be some kind of archive such as tar, gz, zip, etc
#            3: a descent name for the directory you want to install the program in, e.g for "ncbi-blast-123.123.123.33" i would use "blast"
#            or for "samtools-1.1.tar.bz2" i would suggest "samtools"
#e.g.        ./install_binary.sh "hdn,cn1,cn2" "http://downloads.sourceforge.net/project/samtools/samtools/1.1/samtools-1.1.tar.bz2" "samtools"

#TODO: this script breaks if zip files contain subdirs, then the PATH cannot be updated correctly
#TODO: this script is not working at all at the moment!

nodelist="$1"
download_url="$2"
alias="$3"


filename=$(basename "$download_url")
temp_dir=/tmp
src_path=/opt/software/src
bin_path=/opt/software

#the following line makes available four environment variables in this script starting with "extract_..."
source ./extractor.sh $filename

wget $download_url -P $temp_dir
echo "in some archives the binary files are located in some subdirectories such as ./bin" 
echo "please have a look at the archive and define a possible binary subfolder here (leave blank if the binary is located in the root dir)"
echo "this is relative to the root folder! if an zip archive has the following structure: ./myApp/bin/start.sh" 
echo "one would define bin as the directory where the executable is in"
echo "Press any key to see the contents of the archive"
read dummy
$extract_tool $extract_list_flag $temp_dir/$filename

echo "define a possible subdir if executable is not in root dir"
read bin_dir
echo "binary will be stored in: $bin_path/$alias/$bin_dir"

#copy the package to all defined nodes
$BEO_SCRIPTS/node_copier.sh "$nodelist" "$temp_dir/$filename"
$BEO_SCRIPTS/node_executor.sh "$nodelist" "mv $temp_dir/$filename $src_path"

#extract on nodes
EXTRACT_CMD="$extract_tool $extract_flag $src_path/$filename $extract_to_flag $bin_path/$alias"
echo $EXTRACT_CMD
$BEO_SCRIPTS/node_executor.sh "$nodelist" "$EXTRACT_CMD;\
echo 'export PATH=\$PATH:$bin_path/$alias' >>/etc/profile.d/$alias.sh;\
chmod +x /etc/profile.d/$alias.sh;
source /etc/profile.d/$alias.sh;"


