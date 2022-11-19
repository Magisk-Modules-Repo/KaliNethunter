#!/sbin/sh

ui_print " ";
ui_print "##################################################";
ui_print "##                                              ##";
ui_print "##  88      a8P         db        88        88  ##";
ui_print "##  88    .88'         d88b       88        88  ##";
ui_print "##  88   88'          d8''8b      88        88  ##";
ui_print "##  88 d88           d8'  '8b     88        88  ##";
ui_print "##  8888'88.        d8YaaaaY8b    88        88  ##";
ui_print "##  88P   Y8b      d8''''''''8b   88        88  ##";
ui_print "##  88     '88.   d8'        '8b  88        88  ##";
ui_print "##  88       Y8b d8'          '8b 888888888 88  ##";
ui_print "##                                              ##";
ui_print "################### NetHunter ####################";
ui_print "         ******************************";
ui_print "         Powered by Magisk (@topjohnwu)";
ui_print "         ******************************";
ui_print " ";

[ -z $OUTFD ] && OUTFD=/proc/self/fd/$2 || OUTFD=/proc/self/fd/$OUTFD;
[ ! -z $ZIP ] && { ZIPFILE="$ZIP"; unset ZIP; }
[ -z $ZIPFILE ] && ZIPFILE="$3";

readlink /proc/$$/fd/$2 2>/dev/null | grep /tmp >/dev/null;
if [ "$?" -eq "0" ]; then
  OUTFD=/proc/self/fd/0;
  for FD in `ls /proc/$$/fd`; do
    readlink /proc/$$/fd/$FD 2>/dev/null | grep pipe >/dev/null;
    if [ "$?" -eq "0" ]; then
      ps | grep " 3 $FD " | grep -v grep >/dev/null;
      if [ "$?" -eq "0" ]; then
        OUTFD=/proc/self/fd/$FD;
        break;
      fi;
    fi;
  done;
fi;

test -e /data/adb/magisk && adb=adb;
ps | grep zygote | grep -v grep >/dev/null && BOOTMODE=true || BOOTMODE=false;
$BOOTMODE || ps -A 2>/dev/null | grep zygote | grep -v grep >/dev/null && BOOTMODE=true;
if $BOOTMODE; then
  OUTFD=/proc/self/fd/0;
  dev=/dev;
  devtmp=/dev/tmp;
  if [ ! -f /data/$adb/magisk_merge.img -a ! -e /data/adb/modules ]; then
    (/system/bin/make_ext4fs -b 4096 -l 64M /data/$adb/magisk_merge.img || /system/bin/mke2fs -b 4096 -t ext4 /data/$adb/magisk_merge.img 64M) >/dev/null;
  fi;
  test -e /magisk/.core/busybox && magiskbb=/magisk/.core/busybox;
  test -e /sbin/.core/busybox && magiskbb=/sbin/.core/busybox;
  test -e /sbin/.magisk/busybox && magiskbb=/sbin/.magisk/busybox;
  test "$magiskbb" && export PATH="$magiskbb:$PATH";
fi;

ui_print() { $BOOTMODE && echo "$1" || echo -e "ui_print $1\nui_print" >> $OUTFD; }
show_progress() { echo "progress $1 $2" >> $OUTFD; }
set_progress() { echo "set_progress $1" >> $OUTFD; }
file_getprop() { grep "^$2" "$1" | head -n1 | cut -d= -f2; }
find_target() {

if [ -e /data/$adb/magisk -a ! -e /data/$adb/magisk.img -a ! -e /data/adb/modules ]; then
    make_ext4fs -b 4096 -l 64M /data/$adb/magisk.img || mke2fs -b 4096 -t ext4 /data/$adb/magisk.img 64M;
  fi;

  if [ ! "$system" ]; then
    suimg=`(ls /data/$adb/magisk_merge.img || ls /data/su.img || ls /cache/su.img || ls /data/$adb/magisk.img || ls /cache/magisk.img) 2>/dev/null`;
    mnt=$devtmp/$(basename $suimg .img);
  fi;
  if [ "$suimg" ]; then
    umount $mnt;
    test ! -e $mnt && mkdir -p $mnt;
    mount -t ext4 -o rw,noatime $suimg $mnt;
    for i in 0 1 2 3 4 5 6 7; do
      test "$(mount | grep " $mnt ")" && break;
      loop=/dev/block/loop$i;
      if [ ! -f "$loop" -o ! -b "$loop" ]; then
        mknod $loop b 7 $i;
      fi;
      losetup $loop $suimg && mount -t ext4 -o loop,noatime $loop $mnt;
    done;
    case $mnt in
      */magisk*) magisk=/$modname/system;;
    esac;
    if [ -d "$mnt$magisk/xbin" -o "$magisk" -a -d "$root/system/xbin" ]; then
      target=$mnt$magisk/xbin;
    else
      target=$mnt$magisk/bin;
    fi;
  else
    mnt=$(dirname `find /data -name supersu_is_here | head -n1` 2>/dev/null);
    if [ -e "$mnt" -a ! "$system" ]; then
      target=$mnt/xbin;
    elif [ -e "/data/adb/modules" -a ! "$system" ]; then
      mnt=/data/adb/modules_update;
      magisk=/$modname/system;
      if [ -d "$mnt$magisk/xbin" -o "$magisk" -a -d "$root/system/xbin" ]; then
        target=$mnt$magisk/xbin;
      else
        target=$mnt$magisk/bin;
      fi;
    else
      mount -o rw,remount /system;
      mount /system;
      if [ -d "$root/system/xbin" ]; then
        target=$root/system/xbin;
      else
        target=$root/system/bin;
      fi;
    fi;
  fi;
  ui_print "Using path: $target";
}
custom_cleanup() {
  cleanup="$target";
  if [ "$target" == "$mnt$magisk/xbin" -a -f "$mnt$magisk/bin/busybox" ]; then
    $target/busybox rm -f $mnt$magisk/bin/busybox;
    cleanup="$mnt$magisk/bin $target";
  fi;
  for dir in $cleanup; do
    cd $dir;
    for i in $(ls -al `find -type l` | $target/busybox awk '{ print $(NF-2) ":" $NF }'); do
      case $(echo $i | $target/busybox cut -d: -f2) in
        *busybox) list="$list $dir/$(echo $i | $target/busybox cut -d: -f1)";;
      esac;
    done;
  done;
  $target/busybox rm -f $list;
}
abort() {
  ui_print " ";
  ui_print "Your system has not been changed.";
  ui_print " ";
  ui_print "Script will now exit...";
  ui_print " ";
  umount $mnt;
  umount /system;
  umount /data;
  umount /cache;
  exit 1;
}

modname=KaliNethunter;
show_progress 1.34 0;

mount -o ro /system;
mount /data;
mount /cache;
test -f /system/system/build.prop && root=/system;
set_progress 0.2;


if [ -f /data/.$modname ]; then
  choice=$(cat /data/.$modname);
else
  choice=$(basename "$ZIPFILE");
fi;

case $choice in
  *uninstall*|*Uninstall*|*UNINSTALL*) action=uninstallation;;
  *) action=installation;;
esac;

case $choice in
  *nolinks*|*NoLinks*|*NOLINKS*) nolinks=1;
esac;

case $choice in
  *system*|*System*|*SYSTEM*) system=1; ui_print " "; ui_print "Warning: Forcing a system $action!";;
esac;

if [ "$action" == "installation" ]; then
  ui_print " ";
  ui_print "Extracting files...";
  mkdir -p $dev/tmp/$modname;
  cd $dev/tmp/$modname;
  unzip -o "$ZIPFILE";
  set_progress 0.3;

  ui_print " ";
  ui_print "Installing...";
  abi=`file_getprop $root/system/build.prop ro.product.cpu.abi`;
  case $abi in
    arm*|x86*) ;;
    *) abi=`getprop ro.product.cpu.abi`;;
  esac;
  case $abi in
    arm*|x86*) ;;
    *) abi=`file_getprop /default.prop ro.product.cpu.abi`;;
  esac;
  case $abi in
    arm64*) arch=arm64;;
    arm*) arch=arm;;
    x86_64*) arch=amd64;;
    x86*) arch=i386;;
    *) ui_print "Unknown architecture: $abi"; abort;;
  esac;
  ui_print "Using architecture: $arch";

  find_target;
  pm install apps/NetHunter.apk
  pm install apps/NetHunterKeX.apk
  pm install apps/NetHunterStore.apk
  pm install apps/NetHunterStorePrivilegedExtension.apk
  pm install apps/NetHunterTerminal.apk

  cp -rf system/etc/ /system/
  mkdir -p $target;
  cp -f busybox-$arch $target/busybox;
  chown 0:0 "$target/busybox";
  chmod 755 "$target/busybox";
  if [ "$magisk" ]; then
    cp -f module.prop $mnt/$modname/;
    touch $mnt/$modname/auto_mount;
    if $BOOTMODE; then
      test -e /magisk && imgmnt=/magisk || imgmnt=/sbin/.core/img;
      test -e /sbin/.magisk/img && imgmnt=/sbin/.magisk/img;
      test -e /data/adb/modules && imgmnt=/data/adb/modules;
      mkdir -p "$imgmnt/$modname";
      touch "$imgmnt/$modname/update";
      cp -f module.prop "$imgmnt/$modname/";
    fi;
  fi;
  set_progress 0.8;

  ui_print " ";
  ui_print "Cleaning...";
  custom_cleanup;

  if [ ! "$nolinks" ]; then
    ui_print " ";
    ui_print "Creating symlinks...";
    sysbin="$(ls $root/system/bin)";
    test $BOOTMODE && existbin="$(ls $imgmnt/$modname/system/bin 2>/dev/null)";
    for applet in `$target/busybox --list`; do
      case $target in
        */bin)
          if [ "$(echo "$sysbin" | $target/busybox grep "^$applet$")" ]; then
            if $BOOTMODE && [ "$(echo "$existbin" | $target/busybox grep "^$applet$")" ]; then
              $target/busybox ln -sf busybox $applet;
            fi;
          else
            $target/busybox ln -sf busybox $applet;
          fi;
        ;;
        *) $target/busybox ln -sf busybox $applet;;
      esac;
    done;
  fi;
  test "$magisk" && chcon -hR 'u:object_r:system_file:s0' "$mnt/$modname";
else
  ui_print " ";
  ui_print "Uninstalling...";

  find_target;

  if [ ! -f "$target/busybox" ]; then
    ui_print " ";
    ui_print "No busybox installation found!";
    abort;
  fi;

  list=busybox;
  custom_cleanup;
  test "$magisk" && rm -rf /magisk/$modname /sbin/.core/img/$modname /sbin/.magisk/img/$modname /data/adb/modules/$modname;
fi;
set_progress 1.0;

ui_print " ";
ui_print "Unmounting...";
cd /;
test "$suimg" && umount $mnt;
test "$loop" && losetup -d $loop;
umount /system;
umount /data;
umount /cache;
set_progress 1.2;

ui_print " ";
ui_print "Symlinking...";
ln -s /system/xbin/busybox /system/xbin/busybox_nh

ui_print "Cleaning Up..."
rm -rf /data/local/nhsystem/kali*
rm -rf /tmp/$modname /dev/tmp;
ui_print " ";
ui_print "Done!";
set_progress 1.34;
exit 0;
