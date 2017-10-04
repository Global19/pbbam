#!/bin/bash -vex
type module >& /dev/null || . /mnt/software/Modules/current/init/bash

module use /mnt/software/modulefiles
module use /pbi/dept/primary/modulefiles
   
module load cmake/3.9.0
module load ccache/3.3.4
export CCACHE_DIR="/mnt/secondary/Share/tmp/bamboo.${bamboo_shortPlanKey}.ccache"
module load composer_xe/2017.4.196

HTSLIB_VERSION=$(/bin/ls -d src/htslib-*|sed -e 's/.*htslib-//'|sort -V|tail -1)
PBBAM_VERSION=$(grep 'PacBioBAM VERSION ' src/pbbam/CMakeLists.txt|sed -e 's/.*VERSION //'|awk '{print $1}')
# project(PacBioBAM VERSION 0.13.2 LANGUAGES CXX C)
BUILD_NUMBER=0
if [ -n "$bamboo_planRepository_branchName" ]; then
  BUILD_NUMBER=${bamboo_globalBuildNumber:-0}
fi

rm -f *.tgz || true
rm -rf pbbam* || true
rm -rf prefix && mkdir -p prefix
cd src/htslib-${HTSLIB_VERSION}
export CCACHE_BASEDIR=$PWD
CC=icc CXX=icpc \
CFLAGS='-fPIC -Os' bash ./configure --prefix=$PWD/../../prefix
VERBOSE=1 make CC='ccache icc' install
rm -rf $PWD/../../prefix/lib/pkgconfig

cd -
cd src/pbbam
export CCACHE_BASEDIR=$PWD
rm -rf build && mkdir -p build
cd build
cmake \
  -DCMAKE_CXX_COMPILER="ccache" \
  -DCMAKE_CXX_COMPILER_ARG1="icpc -fPIC" \
  -DCMAKE_C_COMPILER="ccache" \
  -DCMAKE_C_COMPILER_ARG1="icc -fPIC" \
  -DPacBioBAM_build_shared=OFF \
  -DPacBioBAM_build_docs=OFF \
  -DPacBioBAM_build_tests=OFF \
  -DHTSLIB_INCLUDE_DIRS=$PWD/../../../prefix/include \
  -DHTSLIB_LIBRARIES=$PWD/../../../prefix/lib/libhts.a \
  -DBoost_INCLUDE_DIRS=/mnt/software/b/boost/1.60/include \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_SKIP_BUILD_RPATH=FALSE ..
VERBOSE=1 make -j
tar c bin lib | tar xv -C ../../../prefix/
cd ..
tar c include/pbbam | tar xv -C ../../prefix/
cd ../..

if [ ! -n "$bamboo_planRepository_branchName" ]; then
  SNAPSHOT="_branch_"
fi
if [ "$bamboo_planRepository_branchName" = "develop" ]; then
  SNAPSHOT="SNAPSHOT"
elif [ "$bamboo_planRepository_branchName" = "master" ]; then
  SNAPSHOT=""
else
  SNAPSHOT="_branch_"
fi

rsync -ax --delete prefix/ pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}/

tar zcf pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}
sha1sum pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz | awk -e '{print $1}' >| pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz.sha1
md5sum  pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz | awk -e '{print $1}' >| pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz.md5
if [ "$bamboo_planRepository_branchName" = "develop" -o "$bamboo_planRepository_branchName" = "master" ]; then
  NEXUS_URL=http://ossnexus.pacificbiosciences.com/repository/maven-snapshots/pacbio/seq/pa/pbbam/${PBBAM_VERSION}.${BUILD_NUMBER}
  curl -L -fvn --upload-file pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz.md5  $NEXUS_URL/pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz.md5
  curl -L -fvn --upload-file pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz.sha1 $NEXUS_URL/pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz.sha1
  curl -L -fvn --upload-file pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz      $NEXUS_URL/pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}-x86_64.tgz
else
  echo "[INFO] pbbam-${PBBAM_VERSION}.SNAPSHOT${BUILD_NUMBER}-x86_64.tgz if the branch is develop"
fi

# GCC BUILD

rm -rf gccbuild && mkdir -p gccbuild
cd src/htslib-${HTSLIB_VERSION}
export CCACHE_BASEDIR=$PWD
make distclean
CFLAGS='-fPIC -O' bash ./configure --prefix=$PWD/../../gccbuild
VERBOSE=1 make install
rm -rf $PWD/../../gccbuild/lib/pkgconfig

cd -
cd src/pbbam
export CCACHE_BASEDIR=$PWD
rm -rf build && mkdir -p build
cd build
CFLAGS=-fPIC CXXFLAGS=-fPIC
cmake \
  -DPacBioBAM_build_shared=OFF \
  -DPacBioBAM_build_docs=OFF \
  -DPacBioBAM_build_tests=OFF \
  -DHTSLIB_INCLUDE_DIRS=$PWD/../../../gccbuild/include \
  -DHTSLIB_LIBRARIES=$PWD/../../../gccbuild/lib/libhts.a \
  -DBoost_INCLUDE_DIRS=/mnt/software/b/boost/1.60/include \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_SKIP_BUILD_RPATH=FALSE ..
VERBOSE=1 make -j
tar c bin lib | tar xv -C ../../../gccbuild/
cd ..
tar c include/pbbam | tar xv -C ../../gccbuild/
cd ../..

rsync -ax --delete gccbuild/ pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc/

tar zcf pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc
sha1sum pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz | awk -e '{print $1}' >| pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz.sha1
md5sum  pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz | awk -e '{print $1}' >| pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz.md5
if [ "$bamboo_planRepository_branchName" = "develop" -o "$bamboo_planRepository_branchName" = "master" ]; then
  curl -L -fvn --upload-file pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz.md5  $NEXUS_URL/pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz.md5
  curl -L -fvn --upload-file pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz.sha1 $NEXUS_URL/pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz.sha1
  curl -L -fvn --upload-file pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz      $NEXUS_URL/pbbam-${PBBAM_VERSION}.${SNAPSHOT}${BUILD_NUMBER}gcc-x86_64.tgz
else
  echo "[INFO] pbbam-${PBBAM_VERSION}.SNAPSHOT${BUILD_NUMBER}gcc-x86_64.tgz if the branch is develop"
  exit
fi
