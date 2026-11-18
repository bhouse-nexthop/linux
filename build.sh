#!/bin/bash
# Build Ubuntu noble's linux-hwe-7.0 (generic flavour) with the patches in patches/.
# Runs inside an ubuntu:24.04 container; the repository is mounted at /work,
# the build tree goes in $BUILD_DIR and the .debs land in /work/out.
set -euo pipefail

cd /work
UBUNTU_VERSION=$(cat UBUNTU_VERSION)
VERSION="${UBUNTU_VERSION}$(cat LOCAL_SUFFIX)"
SRC_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/linux-hwe-7.0/${UBUNTU_VERSION}/linux-hwe-7.0_${UBUNTU_VERSION}.dsc"
BUILD_DIR=${BUILD_DIR:-/work/build}

export DEBIAN_FRONTEND=noninteractive
export DEBFULLNAME="Brad House" DEBEMAIL="bhouse@nexthop.ai"

apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    build-essential devscripts equivs fakeroot ca-certificates curl python3 >/dev/null

rm -rf "$BUILD_DIR" /work/out && mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
dget -q -u -d "$SRC_URL"
dpkg-source -x "linux-hwe-7.0_${UBUNTU_VERSION}.dsc" src
cd src

for p in $(cat /work/patches/series); do
    patch -p1 --no-backup-if-mismatch < "/work/patches/$p"
done

. debian/debian.env
dch -c "$DEBIAN/changelog" -v "$VERSION" -D noble \
    "Add $(paste -sd' ' /work/patches/series) (see https://github.com/bhouse-nexthop/linux/tree/noble-nexthop)."

fakeroot debian/rules clean
mk-build-deps -i -r -t "apt-get -y -qq --no-install-recommends" debian/control >/dev/null
rm -f linux-hwe-7.0-build-deps_*

# The patch doesn't change the module ABI; skip Ubuntu's ABI/module/retpoline
# comparisons against the previous upload, and debug symbols.
KOPTS="skipabi=true skipmodule=true skipretpoline=true skipdbg=true"
fakeroot debian/rules binary-headers $KOPTS
fakeroot debian/rules binary-arch $KOPTS

cd ..
mkdir -p /work/out
cp ./*.deb /work/out/
ls -l /work/out
