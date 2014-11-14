#!/bin/bash

#this script downloads a file locally from any public server
#than compiles it using some parametrized compile instructions
#than installs the software in a standard directory

#parameters: 1: the nodes you want to install the software to
#            2: the download URL, must be some kind of archive such as tar, gz, zip, etc
#            3: a descent name for the directory you want to install the program in, e.g for "ncbi-blast-123.123.123.33" i would use "blast"
#            4: the compiling instructions in a string, e.g,: "configure --prefix=/opt/bla;make;make test;make install"
#            5: if this parameter is set and equals 1, it will be a compile dry-run to test if the software can be compiled completely

#  example:
#    ./install_source.sh "hdn,cn1,cn2" \
#    "http://ftp.gnu.org/gnu/sed/sed-1.18.tar.gz" \
#    "sed" \
#    "./configure --prefix=/opt/software;make;make install"


#Hint: for git archives wget does not work, a solution is to clone the repository into $temp_dir (normally located in /tmp)
#      and start the script with normal url. It will not redownload the archive if it can be found int $temp_dir so the rest of the script will run
#      sucessfully, e.g.:
#  cd /tmp;git clone https://github.com/josemiserra/hcell.git
#    ./install_source.sh "hdn,cn1,cn2" \
#        "https://github.com/josemiserra/hcell.git;./install_source.sh" \
#     "hcell" \
#    "./configure --prefix=/opt/software;make;make install"

#TODO: this script breaks if zip files contain subdirs, then the PATH cannot be updated correctly


nodelist="$1"
download_url="$2"
alias="$3"
compile_string="$4"
compile_dry_run="$5"


filename=$(basename "$download_url")
temp_dir=/tmp
src_path=/opt/software/src
build_path=/opt/software/build
bin_path=/opt/software

#the following line makes available four environment variables in this script starting with "extract_..."
source ./extractor.sh $filename

#only download once .. if program will be run multiple times
if [ ! -f $temp_dir/$filename ]
then
   wget $download_url -P $temp_dir
fi

#test if we can compile at all, only local
if [ "$compile_dry_run" == "1" ]
then
   cp $temp_dir/$filename $temp_dir/"temp_"$filename
   echo $extract_tool $extract_flag $temp_dir/"temp_"$filename $extract_to_flag $temp_dir/$alias
   mkdir $temp_dir/$alias
   $extract_tool $extract_flag $temp_dir/temp_$filename $extract_to_flag $temp_dir/$alias
   cd $temp_dir/$alias
   eval $compile_string
   exit 1
fi

echo "in some archives the source code is located in some subdirectories such as ./src etc"
echo "please have a look at the archive and define a possible binary subfolder here (leave blank if the binary is located in the root dir)"
echo "this is relative to the root folder! if an zip archive has the following structure: ./myApp/bin/start.sh"
echo "one would define bin as the directory where the executable is in"
echo "Press any key to see the contents of the archive"
read dummy
echo $extract_tool $extract_list_flag $temp_dir/$filename
$extract_tool $extract_list_flag $temp_dir/$filename

echo "define a possible subdir if source code is not in root dir"
read src_dir


#copy the source code to all nodes
$BEO_SCRIPTS/node_copier.sh "$nodelist" "$temp_dir/$filename"
$BEO_SCRIPTS/node_executor.sh "$nodelist" "mv $temp_dir/$filename $src_path"

#extract on nodes
EXTRACT_CMD="$extract_tool $extract_flag $src_path/$filename $extract_to_flag $build_path/$alias"
echo $EXTRACT_CMD
mkdir $build_path/$alias
$BEO_SCRIPTS/node_executor.sh "$nodelist" "$EXTRACT_CMD"
#now build this thing
$BEO_SCRIPTS/node_executor.sh "$nodelist" "cd $build_path/$alias \
$compile_string"

#add binaries to our PATH variable
$BEO_SCRIPTS/node_executor.sh "echo 'export PATH=\$PATH:$bin_path/$alias' >>/etc/profile.d/$alias.sh;\
chmod +x /etc/profile.d/$alias.sh;
source /etc/profile.d/$alias.sh;"
