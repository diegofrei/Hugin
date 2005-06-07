#!/bin/sh

wxVersion="2.6.1"
resdir="build/HuginOSX.app/Contents/Resources"
xrcsrcdir="../src/hugin/xrc"

rm -fR $resdir/xrc
echo copying xrc folder to $resdir/xrc
cp -r $xrcsrcdir $resdir/
echo removing extra files from xrc folder
rm -f $resdir/xrc/.??*
rm -fR $resdir/xrc/CVS
rm -f $resdir/xrc/data/.??*
rm -fR $resdir/xrc/data/CVS

#for xrcfile in `ls $resdir/xrc | grep mac.xrc`
#do
#  echo using $resdir/xrc/$xrcfile instead of $resdir/xrc/`echo $xrcfile|sed s/-mac.xrc/.xrc/`
#  mv -f $resdir/xrc/$xrcfile $resdir/xrc/`echo $xrcfile|sed s/-mac.xrc/.xrc/`
#done

echo patching $resdir/xrc/cp_editor_panel-2.5.xrc to use wxChoice instead of wxNotebook
mv $resdir/xrc/cp_editor_panel-2.5.xrc $resdir/xrc/cp_editor_panel-2.5.xrc-bk
sed -e s/wxNotebook/wxChoice/ -e s/cp_editor_left_tab/cp_editor_left_choice/ -e s/cp_editor_right_tab/cp_editor_right_choice/ $resdir/xrc/cp_editor_panel-2.5.xrc-bk > $resdir/xrc/cp_editor_panel-2.5.xrc


for lang in `cat languages`
do
 
 echo 
 echo "Language: $lang"

 localisedresdir="$resdir/$lang.lproj"
 localedir="$localisedresdir/locale"

 rm -fR $localisedresdir
 echo "deleting $localisedresdir"

 mkdir "$localisedresdir"
 echo "making $localisedresdir"
 mkdir "$localedir"
 echo "making $localedir"

 if [ $lang = "en" ]
 then
  continue
 fi

 echo "wxstd.mo to $lang.po"
 msgfmt -v -o "$localedir/wxstd.mo" "../../wxMac-$wxVersion/locale/$lang.po"
 echo "hugin.mo to $lang.po"
 msgfmt -v -o "$localedir/hugin.mo" "../src/hugin/po/$lang.po"

 for file in `ls $xrcsrcdir/data | grep _$lang.htm`
 do
  echo copying $file to $localisedresdir/`echo $file|sed s/_$lang//`
  echo  rewriting \'src=\"\' to \'src=\"../xrc/data/\'
  sed s/src\=\"/src\=\"..\\/xrc\\/data\\// "$xrcsrcdir/data/$file" > $localisedresdir/`echo $file|sed s/_$lang//`
 done

 for file in `ls $xrcsrcdir/data | grep _$lang.html`
 do
  echo copying $file to $localisedresdir/`echo $file|sed s/_$lang//`
  echo  rewriting \'src=\"\' to \'src=\"../xrc/data/\'
  sed s/src\=\"/src\=\"..\\/xrc\\/data\\// "$xrcsrcdir/data/$file" > $localisedresdir/`echo $file|sed s/_$lang//`
 done

 for file in `ls $xrcsrcdir/data | grep _$lang-UTF8.txt`
 do
  echo copying $file to $localisedresdir/`echo $file|sed s/_$lang//`
  cp "$xrcsrcdir/data/$file" $localisedresdir/`echo $file|sed s/_$lang//`
 done

done