#!/bin/sh

#  Generate a script to compile Canu using the Holy Build Box.

echo  > build-linux.sh  \#\!/bin/bash
echo >> build-linux.sh  yum install -y git
echo >> build-linux.sh  cd /build/src
echo >> build-linux.sh  gmake -j 12 \> ../Linux-amd64.out 2\>\&1
echo >> build-linux.sh  cd ..
#echo >> build-linux.sh  rm -rf Linux-amd64/obj
#echo >> build-linux.sh  tar -cf canu-linux.Linux-amd64.tar  canu-linux/README* canu-linux/Linux-amd64

chmod 755 build-linux.sh

echo ""
echo "-- Build Linux and make tarballs."
echo ""

echo "% docker run ..."
docker run \
  -v `pwd`:/build \
  -t \
  -i \
  --rm phusion/holy-build-box-64:latest /hbb_exe/activate-exec bash /build/build-linux.sh \
> build-linux.sh.out 2>&1

rm -f build-linux.sh

echo ""
echo "-- Build success?"
echo ""

tail -n 1 build-linux.sh.out | head -n 1
tail -n 2 Linux-amd64.out | head -n 1

#  Fetch the Upload Agent and install in our bin/.

if [ ! -e src/pipelines/dx-canu/resources/bin/ua ] ; then
  echo ""
  echo "-- Fetch UploadAgent."
  echo ""

  curl -L -R -O https://dnanexus-sdk.s3.amazonaws.com/dnanexus-upload-agent-1.5.31-osx.zip
  curl -L -R -O https://dnanexus-sdk.s3.amazonaws.com/dnanexus-upload-agent-1.5.31-linux.tar.gz

  tar zxf dnanexus-upload-agent-1.5.31-linux.tar.gz

  mv dnanexus-upload-agent-1.5.31-linux/ua src/pipelines/dx-canu/resources/bin/

  #rm -rf dnanexus-upload-agent-1.5.31-linux.tar.gz
  rm -rf dnanexus-upload-agent-1.5.31-linux
fi

#   Remove the old app.

echo ""
echo "-- Purge previous dx-canu build."
echo ""

echo "% rm -rf dx-canu/"
rm -rf   dx-canu/
mkdir -p dx-canu/
mkdir -p dx-canu/resources/bin/
mkdir -p dx-canu/resources/usr/bin/
mkdir -p dx-canu/resources/usr/lib/
mkdir -p dx-canu/resources/usr/share/

#rm -rf dx-canu/resources/usr/bin/
#rm -rf dx-canu/resources/usr/lib/
#rm -rf dx-canu/resources/usr/share/

#mkdir -p dx-canu/src

#rm  -f dx-canu/dxapp.json
#rm  -f dx-canu/

#cp -p src/pipelines/dx-canu/dxapp.json                             dx-canu/dxapp.json
#cp -p src/pipelines/dx-canu/src/canu-job-launcher.sh               dx-canu/src/canu-job-launcher.sh
#cp -p src/pipelines/dx-canu/resources/bin/dx-get-instance-info.py  dx-canu/src/resources/bin/dx-get-instance-info.py

#if [ ! -e dx-canu/resources/bin/ua ] ; then
#  cp -p src/pipelines/dx-canu/resources/bin/ua dx-canu/resources/bin/ua
#fi

#  Package all that up into dx-canu.

echo ""
echo "-- Package new bits into dx-canu build."
echo ""

echo "% rsync ..."
rsync -a src/pipelines/dx-canu/  dx-canu/
rsync -a Linux-amd64/bin/        dx-canu/resources/usr/bin/
rsync -a Linux-amd64/lib/        dx-canu/resources/usr/lib/
rsync -a Linux-amd64/share/      dx-canu/resources/usr/share/

#rm -fr Linux-amd64/obj Linux-amd64.tar Linux-amd64.tar.gz
#tar -cf Linux-amd64.tar Linux-amd64
#gzip -1v Linux-amd64.tar
#dx rm Linux-amd64.tar.gz
#dx upload Linux-amd64.tar.gz

echo ""
echo "-- Build the DNAnexus app."
echo ""

echo "% dx build -f dx-canu"
dx build -f dx-canu

exit 0
