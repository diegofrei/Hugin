# ------------------
# enblend 3.2   
# ------------------
# $Id: enblend3.sh 1908 2007-02-05 14:59:45Z ippei $
# Copyright (c) 2007, Ippei Ukai

# prepare

# export REPOSITORYDIR="/PATH2HUGIN/mac/ExternalPrograms/repository" \
# ARCHS="ppc i386" \
#  ppcTARGET="powerpc-apple-darwin7" \
#  i386TARGET="i386-apple-darwin8" \
#  ppcMACSDKDIR="/Developer/SDKs/MacOSX10.3.9.sdk" \
#  i386MACSDKDIR="/Developer/SDKs/MacOSX10.4u.sdk" \
#  ppcONLYARG="-mcpu=G3 -mtune=G4" \
#  i386ONLYARG="-mfpmath=sse -msse2 -mtune=pentium-m -ftree-vectorize" \
#  ppc64ONLYARG="-mcpu=G5 -mtune=G5 -ftree-vectorize" \
#  OTHERARGs="";

# -------------------------------
# 20091206.0 sg Script tested and used to build 2009.4.0-RC3
# -------------------------------

# init

let NUMARCH="0"

for i in $ARCHS
do
  NUMARCH=$(($NUMARCH + 1))
done

mkdir -p "$REPOSITORYDIR/bin";
mkdir -p "$REPOSITORYDIR/lib";
mkdir -p "$REPOSITORYDIR/include";

# compile

for ARCH in $ARCHS
do

 mkdir -p "$REPOSITORYDIR/arch/$ARCH/bin";
 mkdir -p "$REPOSITORYDIR/arch/$ARCH/lib";
 mkdir -p "$REPOSITORYDIR/arch/$ARCH/include";

 ARCHARGs=""
 MACSDKDIR=""

 if [ $ARCH = "i386" -o $ARCH = "i686" ] ; then
   TARGET=$i386TARGET
   MACSDKDIR=$i386MACSDKDIR
   ARCHARGs="$i386ONLYARG"
   OSVERSION="$i386OSVERSION"
   CC=$i386CC
   CXX=$i386CXX
 elif [ $ARCH = "ppc" -o $ARCH = "ppc750" -o $ARCH = "ppc7400" ] ; then
   TARGET=$ppcTARGET
   MACSDKDIR=$ppcMACSDKDIR
   ARCHARGs="$ppcONLYARG"
   OSVERSION="$ppcOSVERSION"
   CC=$ppcCC
   CXX=$ppcCXX
 elif [ $ARCH = "ppc64" -o $ARCH = "ppc970" ] ; then
   TARGET=$ppc64TARGET
   MACSDKDIR=$ppc64MACSDKDIR
   ARCHARGs="$ppc64ONLYARG"
   OSVERSION="$ppc64OSVERSION"
   CC=$ppc64CC
   CXX=$ppc64CXX
 elif [ $ARCH = "x86_64" ] ; then
   TARGET=$x64TARGET
   MACSDKDIR=$x64MACSDKDIR
   ARCHARGs="$x64ONLYARG"
   OSVERSION="$x64OSVERSION"
   CC=$x64CC
   CXX=$x64CXX
 fi

 env \
   CC=$CC CXX=$CXX \
   CFLAGS="-isysroot $MACSDKDIR -arch $ARCH $ARCHARGs $OTHERARGs -dead_strip" \
   CXXFLAGS="-isysroot $MACSDKDIR -arch $ARCH $ARCHARGs $OTHERARGs -dead_strip" \
   CPPFLAGS="-I$REPOSITORYDIR/include -I$REPOSITORYDIR/include/OpenEXR -I/usr/include" \
   LDFLAGS="-L$REPOSITORYDIR/lib -L/usr/lib -mmacosx-version-min=$OSVERSION -dead_strip" \
   NEXT_ROOT="$MACSDKDIR" \
   PKG_CONFIG_PATH="$REPOSITORYDIR/lib/pkgconfig" \
   ./configure --prefix="$REPOSITORYDIR" --disable-dependency-tracking --enable-image-cache=yes \
     --host="$TARGET" --exec-prefix=$REPOSITORYDIR/arch/$ARCH --with-apple-opengl-framework \
   ;

 # hack; AC_FUNC_MALLOC sucks!!

 mv ./config.h ./config.h-copy; 
 sed -e 's/HAVE_MALLOC\ 0/HAVE_MALLOC\ 1/' \
     -e 's/rpl_malloc/malloc/' \
     "./config.h-copy" > "./config.h";

 # well, I prefer -O2
 mv src/Makefile src/Makefile.copy
 sed 's/-O3/-O2/g' src/Makefile.copy > src/Makefile

 make clean;
 make all;
 make install;
 
done


# merge execs

for program in bin/enblend bin/enfuse
do

 if [ $NUMARCH -eq 1 ] ; then
   if [ -f $REPOSITORYDIR/arch/$ARCHS/$program ] ; then
		 echo "Moving arch/$ARCHS/$program to $program"
  	 mv "$REPOSITORYDIR/arch/$ARCHS/$program" "$REPOSITORYDIR/$program";
  	 strip "$REPOSITORYDIR/$program";
  	 continue
	 else
		 echo "Program arch/$ARCHS/$program not found. Aborting build";
		 exit 1;
	 fi
 fi

 LIPOARGs=""

 for ARCH in $ARCHS
 do
 	if [ -f $REPOSITORYDIR/arch/$ARCH/$program ] ; then
		echo "Adding arch/$ARCH/$program to bundle"
 		LIPOARGs="$LIPOARGs $REPOSITORYDIR/arch/$ARCH/$program"
	else
		echo "File arch/$ARCH/$program was not found. Aborting build";
		exit 1;
	fi
 done

 lipo $LIPOARGs -create -output "$REPOSITORYDIR/$program";
 #strip "$REPOSITORYDIR/$program";

done

for program in bin/enblend bin/enfuse
do
 strip -x "$REPOSITORYDIR/$program"
done
