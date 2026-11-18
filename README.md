# Ubuntu noble linux-hwe-7.0, with the vxlan nexthop fdb fix

Builds Ubuntu 24.04 (noble)'s `linux-hwe-7.0` source package, generic flavour, with
the patches in `patches/`. Everything else is Ubuntu's package, unchanged.

- `UBUNTU_VERSION`: the Ubuntu source version to build, fetched from Launchpad.
- `LOCAL_SUFFIX`: appended to that version (`7.0.0-43.43~24.04.1` + `+nh1`).
- `patches/`: applied with `patch -p1`, in `series` order.
- `build.sh`: the build, run in an `ubuntu:24.04` container.
- `.github/workflows/build.yml`: builds on every push (packages as a workflow
  artifact) and publishes a GitHub Release for tags named `noble/<version>`.

## The problem

The fix for CVE-2026-98023 (98fc57d16744, "vxlan: reject dynamic fdb entries that
reference a nexthop id") rejects dynamic vxlan fdb entries with an nhid. FRR installs
remote MACs behind an EVPN multihoming Ethernet Segment exactly that way, so they all
fail ("A nexthop fdb cannot be dynamic") and traffic to them floods to every VTEP.

## The patch

Upstream 7308ef8b4a67 ("vxlan: Stop rejecting dynamic FDB entries with a nexthop ID"),
with context adjusted for 7.0. Upstream 7.0.y is EOL, so Ubuntu has to cherry-pick it:
[LP: #2174656](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2174656).

## Installing

The image is unsigned (`linux-image-unsigned-*`), so Secure Boot must be off. Install
all the `.deb`s for the ABI together and hold them; the `+nh1` version sorts above
Ubuntu's same ABI but below its next one.

## Rebasing on a newer Ubuntu update

Set `UBUNTU_VERSION`, push, and check that the patch still applies.
