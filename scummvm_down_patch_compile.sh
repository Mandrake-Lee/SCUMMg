#!/bin/bash
#
#Arg $1	=	temporary directory names
#Arg $2	=	URL that holds the sources to be downloaded as zip
#Arg $3	=	Forced namefile of the zipball to be saved
#Arg $4	=	Source directory where patches lie
#Arg $5	=	Name of the patch file
#
echo "\n==========================="
echo "\t* Downloading scummvm sources"
if [test -d $1]; then
	echo "Folder $1/ exists"
else
	mkdir $1
fi
wget $2 -O $1/$3
echo "\t* Inflating scummvm sources"
unzip -q $1/$3 -d $1
scummvm_src=$(unzip -Zl $1/$3 | head -n3 | grep "drw" | rev | cut -d ' ' -f1 | cut -c 2- | rev)
echo "Variable = $scummvm_src"
echo "\t* Patching scummvm sources"
patch -d $1/$scummvm_src/ -i $4/patches/$5 -p1
echo "\t* Building patched scummvm statically"
(cd $1/$scummvm_src && \
./configure --disable-all-engines \
			--enable-engine=scumm,scumm_7_8,he \
			--disable-fluidsynth &&\
make)
cp $1/$scummvm_src/scummvm ./
echo "===========================\n"