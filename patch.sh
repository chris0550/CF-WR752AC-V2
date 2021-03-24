#!/bin/sh

squashfsOffet=1156180
firmwareMd5="31dbf3c67a6bbbbcf2eff7e2ece2cad8"

#Check if user is root
if [ `id -u` != "0" ]; then
    echo "You have to be root"
    exit 1
fi

#Check if firmware md5 hash
md5=$(md5sum $1)
expectedMd5="$firmwareMd5  $1"
if [ "$md5" != "$expectedMd5" ]; then
    echo "Wrong firmware file. Expected firmware version is CF-WR752ACV2-V2.3.0.5"
    exit 1
fi

#New password
echo  "Enter new password: "
stty -echo
read password1
stty echo
echo  "Repeat password: "
stty -echo
read password2
stty echo
if [ "$password1" != "$password2" ]; then
    echo "Password do not match"
    exit 1
fi
passwordHash=$(openssl passwd -1 $password1)

#Update firmware
mkdir -p /tmp/CFWR752AC_fw
dd if=$1 of=/tmp/CFWR752AC_fw/squashfs bs=1 skip=$squashfsOffet
dd if=$1 of=/tmp/CFWR752AC_fw/uImageheader_lzma bs=1 count=$squashfsOffet skip=0
mkdir -p /tmp/squashfs_unpacked
unsquashfs -f -d /tmp/CFWR752AC_fw/squashfs_unpacked /tmp/CFWR752AC_fw/squashfs 
sed -i "1s|.*|root:${passwordHash}:16518:0:99999:7:::|" /tmp/CFWR752AC_fw/squashfs_unpacked/etc/shadow
mksquashfs /tmp/CFWR752AC_fw/squashfs_unpacked /tmp/CFWR752AC_fw/new_squashfs -comp xz -no-xattrs -b 262144
cat /tmp/CFWR752AC_fw/uImageheader_lzma /tmp/CFWR752AC_fw/new_squashfs > patchedFirmware.bin
rm -r /tmp/CFWR752AC_fw
echo "Finished. Your firmware file is patchedFirmware.bin"
