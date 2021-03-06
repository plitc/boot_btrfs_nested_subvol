#!/bin/sh

### LICENSE // ###
#
# Copyright (c) 2015, Daniel Plominski (Plominski IT Consulting)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
### // LICENSE ###

### ### ### PLITC // ### ### ###


### stage0 // ###
DEBIAN=$(grep "ID" /etc/os-release | egrep -v "VERSION" | sed 's/ID=//g')
DEBVERSION=$(grep "VERSION_ID" /etc/os-release | sed 's/VERSION_ID=//g' | sed 's/"//g')
if [ -z "$DEBVERSION" ]; then
   DEBVERSION9=$(grep -c "stretch" /etc/os-release | sed 's/1/9/g')
fi
MYNAME=$(whoami)
### // stage0 ###

case "$1" in
'create')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

date +%Y%m%d-%H%M > /tmp/boot_btrfs_nested_subvol_date.txt
DATE=$(cat /tmp/boot_btrfs_nested_subvol_date.txt)
DIALOG=$(/usr/bin/which dialog)

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
       : # dummy
   else
       if [ "$DEBVERSION" = "9" ]; then
          : # dummy
       else
          if [ "$DEBVERSION9" = "9" ]; then
             : # dummy
          else
             echo "" # dummy
             echo "" # dummy
             echo "[Error] You need Debian 7 (Wheezy) or 8 (Jessie) or 9 (Stretch) Version"
             exit 1
          fi
       fi
   fi
fi
if [ -z "$DIALOG" ]; then
   echo "<--- --- --->"
   echo "need dialog"
   echo "<--- --- --->"
   apt-get update
   apt-get install dialog
   echo "<--- --- --->"
fi
#
### stage4 // ###
#
## check btrfs rootfilesystem
BTRFSROOT=$(mount | grep "on / type" | awk '{print $5}')
if [ "$BTRFSROOT" = "btrfs" ]; then
   : # dummy
else
   echo "[Error] can't find btrfs rootfilesystem"
   exit 1
fi
## check default subvolume
BTRFSVOL1=$(btrfs subvolume list '/' | grep -c "level")
if [ "$BTRFSVOL1" -ge "1" ]; then
   : # dummy
else
   echo "[Error] won't create new subvolume snapshots inside other subvolume snapshots"
   exit 1
fi
## check default subvolume 2
BTRFSVOL2=$(btrfs subvolume show '/' | grep -c "root")
if [ "$BTRFSVOL2" = "0" ]; then
   : # dummy
else
   echo "[Error] won't create new subvolume snapshots inside other subvolume snapshots"
   exit 1
fi
## check ROOT subvolume
BTRFSSUBVOL=$(btrfs subvolume list '/ROOT' | grep -c "ROOT")
if [ "$BTRFSSUBVOL" = "1" ]; then
   : # dummy
else
   echo "create ROOT subvolume"
   btrfs subvolume create /ROOT
fi
#
### ### ### ### ### ### ### ### ###
#
## create subvolume snapshot
btrfs subvolume snapshot / /ROOT/system-"$DATE"
if [ "$?" != "0" ]; then
   echo "" # dummy
   echo "[Error] subvolume snapshot exists!" 1>&2
   exit 1
fi
#
# snapshot description
SNAPDESC1="/tmp/boot_btrfs_nested_subvol_desc1.txt"
SNAPDESC2="/tmp/boot_btrfs_nested_subvol_desc2.txt"
/bin/echo "test" > "$SNAPDESC1"
dialog --title "Snapshot Description" --backtitle "Snapshot Description" --inputbox "Enter a short snapshot description: (for example: test)" 8 60 "$(cat $SNAPDESC1)" 2>$SNAPDESC2
snapdesc1=$?
case $snapdesc1 in
   0)
SNAPDESC3=$(sed 's/#//g' "$SNAPDESC2" | sed 's/%//g' | sed 's/ //g')
#
## modify subvol fstab
sed -i '/\/ *btrfs/s/defaults/defaults,subvol=ROOT\/system-'$DATE'/' /ROOT/system-"$DATE"/etc/fstab
#
## modify grub
cp /etc/grub.d/40_custom /etc/grub.d/.40_custom_bk_pre_system-"$DATE"
awk "/menuentry 'Debian GNU\/Linux'/,/}/" /boot/grub/grub.cfg > /etc/grub.d/.40_custom_mod1_system-"$DATE"
#
sed -i '/menuentry/s/Linux/Linux -- snapshot '$DATE' -- '$SNAPDESC3'/' /etc/grub.d/.40_custom_mod1_system-"$DATE"
#
sed -i '/vmlinuz/s/$/ rootflags=subvol=ROOT\/system-'$DATE'/' /etc/grub.d/.40_custom_mod1_system-"$DATE"
sed -i '1i\### -- snapshot '$DATE'' /etc/grub.d/.40_custom_mod1_system-"$DATE"
sed -i 's/quiet//g' /etc/grub.d/.40_custom_mod1_system-"$DATE"
#
### (merge grub)
cat /etc/grub.d/.40_custom_mod1_system-"$DATE" >> /etc/grub.d/40_custom
cp -f /etc/grub.d/40_custom /ROOT/system-"$DATE"/etc/grub.d/40_custom
#
### grub update
echo "" # dummy
sleep 2
grub-mkconfig
echo "" # dummy
sleep 2
update-grub
if [ "$?" != "0" ]; then
   echo "" # dummy
   echo "[Error] something goes wrong let's restore the old configuration!" 1>&2
   cp -f /etc/grub.d/.40_custom_bk_pre_system-"$DATE" /etc/grub.d/40_custom
   echo "" # dummy
   sleep 2
   grub-mkconfig
   echo "" # dummy
   sleep 2
   update-grub
   exit 1
fi
#
;;
   1)
      /bin/echo "" # dummy
      /bin/echo "" # dummy
      btrfs subvolume delete /ROOT/system-"$DATE"
      /bin/echo "" # dummy
      /bin/echo "[Error] abort."
      #/ /bin/echo "ERROR:"
      exit 0
;;
   255)
      /bin/echo "" # dummy
      /bin/echo "" # dummy
      btrfs subvolume delete /ROOT/system-"$DATE"
      /bin/echo "" # dummy
      /bin/echo "[ESC] key pressed."
      exit 0
;;
esac
#
# clean up
rm -f /tmp/boot_btrfs_nested_subvol_desc*
#
### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'delete')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

DIALOG=$(/usr/bin/which dialog)

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
      : # dummy
   else
      if [ "$DEBVERSION" = "9" ]; then
         : # dummy
      else
         if [ "$DEBVERSION9" = "9" ]; then
            : # dummy
         else
            echo "" # dummy
            echo "" # dummy
            echo "[Error] You need Debian 7 (Wheezy) or 8 (Jessie) or 9 (Stretch) Version"
            exit 1
         fi
      fi
   fi
fi
if [ -z "$DIALOG" ]; then
   echo "" # dummy
   echo "need dialog"
   echo "<--- --- --->"
   apt-get update
   apt-get install dialog
   echo "<--- --- --->"
fi
#
### stage4 // ###
#
## check btrfs rootfilesystem
BTRFSROOT=$(mount | grep "on / type" | awk '{print $5}')
if [ "$BTRFSROOT" = "btrfs" ]; then
   : # dummy
else
   echo "[Error] can't find btrfs rootfilesystem"
   exit 1
fi
## check default subvolume
BTRFSVOL1=$(btrfs subvolume list '/' | grep -c "level")
if [ "$BTRFSVOL1" -ge "1" ]; then
   : # dummy
else
   echo "[Error] won't delete the current subvolume snapshot inside another one"
   exit 1
fi
## check default subvolume 2
BTRFSVOL2=$(btrfs subvolume show '/' | grep -c "root")
if [ "$BTRFSVOL2" = "0" ]; then
   : # dummy
else
   echo "[Error] won't delete the current subvolume snapshot inside another one"
   exit 1
fi
## check ROOT subvolume
BTRFSSUBVOL=$(btrfs subvolume list '/ROOT' | grep -c "ROOT")
if [ "$BTRFSSUBVOL" = "1" ]; then
   : # dummy
else
   echo "create ROOT subvolume"
   btrfs subvolume create /ROOT
fi
#
### ### ### ### ### ### ### ### ###

LISTSNAPFILE1="/tmp/boot_btrfs_nested_subvol_del1.txt"
LISTSNAPFILE2="/tmp/boot_btrfs_nested_subvol_del2.txt"
LISTSNAPFILE3="/tmp/boot_btrfs_nested_subvol_del3.txt"

btrfs subvolume list '/' | grep "ROOT/system-" | awk '{print $9}' > $LISTSNAPFILE1
nl $LISTSNAPFILE1 | sed 's/ //g' > $LISTSNAPFILE2
/bin/sed 's/$/ off/' $LISTSNAPFILE2 > $LISTSNAPFILE3

LISTSNAPFILE5="/tmp/boot_btrfs_nested_subvol_del5.txt"
dialog --radiolist "Choose one subvolume to delete:" 45 80 60 --file "$LISTSNAPFILE3" 2>$LISTSNAPFILE5
snapdel1=$?
case $snapdel1 in
   0)
LISTSNAPFILE5CHECK=$(cat /tmp/boot_btrfs_nested_subvol_del5.txt)
if [ -z "$LISTSNAPFILE5CHECK" ]; then
      /bin/echo "" # dummy
      /bin/echo "" # dummy
      /bin/echo "[Error] nothing selected"
      exit 1
fi
LISTSNAPFILE6="/tmp/boot_btrfs_nested_subvol_del6.txt"
awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,h[$1]}' "$LISTSNAPFILE3" "$LISTSNAPFILE5" | awk '{print $2}' | sed 's/"//g' > "$LISTSNAPFILE6"
### ### ###
#
SNAPDEL=$(sed 's/ROOT//g' "$LISTSNAPFILE6" | sed 's/^.//')
SNAPDELFULL=$(cat "$LISTSNAPFILE6")
#
# grub restore
cp -f /etc/grub.d/.40_custom_bk_pre_"$SNAPDEL" /etc/grub.d/40_custom
if [ "$?" != "0" ]; then
   echo "" # dummy
   btrfs subvolume delete /"$SNAPDELFULL"
   echo "" # dummy
   echo "[Error] backup config disappeared!" 1>&2
   exit 1
fi
#
# grub update
echo "" # dummy
echo "" # dummy
sleep 2
grub-mkconfig
echo "" # dummy
sleep 2
update-grub
sleep 2
#
# subvolume snapshot delete
echo "" # dummy
btrfs subvolume delete /"$SNAPDELFULL"
#
# clean up
rm -f /tmp/boot_btrfs_nested_subvol_del*
### ### ###
;;
   1)
      /bin/echo "" # dummy
      /bin/echo "" # dummy
      #/ /bin/echo "ERROR:"
      exit 0
;;
   255)
      /bin/echo "" # dummy
      /bin/echo "" # dummy
      /bin/echo "[ESC] key pressed.   (or no subvolume snapshots for deleting are available)"
      exit 0
;;
esac

### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'clean-up')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
      : # dummy
   else
      if [ "$DEBVERSION" = "9" ]; then
         : # dummy
      else
         if [ "$DEBVERSION9" = "9" ]; then
            : # dummy
         else
            echo "" # dummy
            echo "" # dummy
            echo "[Error] You need Debian 7 (Wheezy) or 8 (Jessie) or 9 (Stretch) Version"
            exit 1
         fi
      fi
   fi
fi
#
### stage4 // ###
#
## check btrfs rootfilesystem
BTRFSROOT=$(mount | grep "on / type" | awk '{print $5}')
if [ "$BTRFSROOT" = "btrfs" ]; then
   : # dummy
else
   echo "[Error] can't find btrfs rootfilesystem"
   exit 1
fi
### ### ### ### ### ### ### ### ###
ROOTSNAPEXIST=$(btrfs subvolume list '/' | grep "ROOT/system-" | awk '{print $9}' | sed 's/ROOT//g' | sed 's/^.//g' | sed 's/\/SUB//g' | sed 's/\// /g' | awk '{print $1}' | sort | uniq)
SUBROOTSNAPEXIST=$(btrfs subvolume list '/' | grep "ROOT/system-" | awk '{print $9}' | sed 's/ROOT//g' | sed 's/^.//g' | sed 's/\/SUB//g' | sed 's/\// /g' | awk '{print $2}' | sed '/^\s*$/d' | sort | uniq)

find /etc/grub.d/ -name ".40_custom_*" | egrep -v "$ROOTSNAPEXIST|$SUBROOTSNAPEXIST" | xargs -L1 rm -fv

if [ -z "$ROOTSNAPEXIST" ]; then
   if [ -z "$SUBROOTSNAPEXIST" ]; then
      rm -fv /etc/grub.d/.40_custom_*
   fi
fi

### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'create-nested')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

date +%Y%m%d-%H%M > /tmp/boot_btrfs_nested_subvol_date.txt
DATE=$(cat /tmp/boot_btrfs_nested_subvol_date.txt)
DIALOG=$(/usr/bin/which dialog)

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
      : # dummy
   else
      if [ "$DEBVERSION" = "9" ]; then
         : # dummy
      else
         if [ "$DEBVERSION9" = "9" ]; then
            : # dummy
         else
            echo "" # dummy
            echo "" # dummy
            echo "[Error] You need Debian 7 (Wheezy) or 8 (Jessie) or 9 (Stretch) Version"
            exit 1
         fi
      fi
   fi
fi
if [ -z "$DIALOG" ]; then
   echo "<--- --- --->"
   echo "need dialog"
   echo "<--- --- --->"
   apt-get update
   apt-get install dialog
   echo "<--- --- --->"
fi
#
### stage4 // ###
#
## check btrfs rootfilesystem
BTRFSROOT=$(mount | grep "on / type" | awk '{print $5}')
if [ "$BTRFSROOT" = "btrfs" ]; then
   : # dummy
else
   echo "[Error] can't find btrfs rootfilesystem"
   exit 1
fi
## check default subvolume
BTRFSVOL1=$(btrfs subvolume list '/' | grep -c "level")
if [ "$BTRFSVOL1" -ge "1" ]; then
   : # dummy
else
   echo "[Error] won't create new subvolume snapshots on top of the ROOT subvolume, please use the 'create' command"
   exit 1
fi
## check default subvolume 2
BTRFSVOL2=$(btrfs subvolume show '/' | grep -c "root")
if [ "$BTRFSVOL2" = "1" ]; then
   echo "[Error] won't create new subvolume snapshots on top of the ROOT subvolume, please use the 'create' command"
   exit 1
else
   : # dummy
fi
## check SUBROOT subvolume
BTRFSSUBVOL=$(btrfs subvolume list '/SUBROOT' | grep -c "SUBROOT")
if [ "$BTRFSSUBVOL" = "1" ]; then
   : # dummy
else
   echo "create SUBROOT subvolume"
   btrfs subvolume create /SUBROOT
fi
#
### ### ### ### ### ### ### ### ###
#
## create subvolume snapshot
btrfs subvolume snapshot / /SUBROOT/system-"$DATE"
if [ "$?" != "0" ]; then
   echo "" # dummy
   echo "[Error] subvolume snapshot exists!" 1>&2
   exit 1
fi
#
CURRDEEP=$(btrfs subvolume show '/' | grep "Name" | awk '{print $2}')
#
# snapshot description
SNAPDESC1="/tmp/boot_btrfs_nested_subvol_desc1.txt"
SNAPDESC2="/tmp/boot_btrfs_nested_subvol_desc2.txt"
/bin/echo "test" > "$SNAPDESC1"
dialog --title "Snapshot Description" --backtitle "Snapshot Description" --inputbox "Enter a short snapshot description: (for example: test)" 8 60 "$(cat $SNAPDESC1)" 2>$SNAPDESC2
snapdesc1=$?
case $snapdesc1 in
   0)
SNAPDESC3=$(sed 's/#//g' "$SNAPDESC2" | sed 's/%//g' | sed 's/ //g')
#
## modify subvol fstab
sed -i '/\/ *btrfs/s/defaults,subvol=ROOT\/'$CURRDEEP'/defaults,subvol=ROOT\/'$CURRDEEP'\/SUBROOT\/system-'$DATE'/' /SUBROOT/system-"$DATE"/etc/fstab
#
## modify grub
cp /etc/grub.d/40_custom /etc/grub.d/.40_custom_bk_pre_subroot_system-"$DATE"
awk "/menuentry 'Debian GNU\/Linux'/,/}/" /boot/grub/grub.cfg > /etc/grub.d/.40_custom_mod1_subroot_system-"$DATE"
#
sed -i '/menuentry/s/Linux/Linux -- snapshot '$CURRDEEP' SUBROOT '$DATE' -- '$SNAPDESC3'/' /etc/grub.d/.40_custom_mod1_subroot_system-"$DATE"
#
sed -i '/vmlinuz/s/$/ rootflags=subvol=ROOT\/'$CURRDEEP'\/SUBROOT\/system-'$DATE'/' /etc/grub.d/.40_custom_mod1_subroot_system-"$DATE"
sed -i '1i\### -- snapshot '$DATE'' /etc/grub.d/.40_custom_mod1_subroot_system-"$DATE"
sed -i 's/quiet//g' /etc/grub.d/.40_custom_mod1_subroot_system-"$DATE"
#
### (merge grub)
cat /etc/grub.d/.40_custom_mod1_subroot_system-"$DATE" >> /etc/grub.d/40_custom
cp -f /etc/grub.d/40_custom /SUBROOT/system-"$DATE"/etc/grub.d/40_custom
#
### grub update
echo "" # dummy
sleep 2
grub-mkconfig
echo "" # dummy
sleep 2
update-grub
if [ "$?" != "0" ]; then
   echo "" # dummy
   echo "[Error] something goes wrong let's restore the old configuration!" 1>&2
   cp -f /etc/grub.d/.40_custom_bk_pre_subroot_system-"$DATE" cp /etc/grub.d/40_custom
   echo "" # dummy
   sleep 2
   grub-mkconfig
   echo "" # dummy
   sleep 2
   update-grub
   exit 1
fi
#
;;
   1)
      /bin/echo "" # dummy
      /bin/echo "" # dummy
      btrfs subvolume delete /SUBROOT/system-"$DATE"
      /bin/echo "" # dummy
      /bin/echo "[Error] abort."
      #/ /bin/echo "ERROR:"
      exit 0
;;
   255)
      /bin/echo "" # dummy
      /bin/echo "" # dummy
      btrfs subvolume delete /SUBROOT/system-"$DATE"
      /bin/echo "" # dummy
      /bin/echo "[ESC] key pressed."
      exit 0
;;
esac
#
# clean up
rm -f /tmp/boot_btrfs_nested_subvol_desc*
#
### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
*)
echo ""
echo "WARNING: subvolboot2 is highly experimental and its not ready for production. Do it at your own risk."
echo "Current Support: 2 layer (1 ROOT/subvolume + 1 ROOT/subvolume/SUBROOT/subvolume)"
echo ""
echo "usage: $0 { create | delete | clean-up | create-nested }"
;;
esac
exit 0


### ### ### // PLITC ### ### ###
# EOF
