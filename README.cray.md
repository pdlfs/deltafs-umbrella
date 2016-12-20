**// This file is written for deltafs adoptors that want to experiment with deltafs on a Cray system**

# deltafs-umbrella

Download, build, and install deltafs, deltafs friends, and their dependencies in a single highly-automated step.

This guide assumes a cray-based computing system.

### Step #1: prepare programming env

```
// First, set cray link type to dynamic (required step)
export CRAYPE_LINK_TYPE="dynamic"

// Second, load related modules in addition to make, automake, pkg-config which should be
// present by default.  The C and CXX compiler are expected to be `cc` and `CC`,
// which are likely wrappers built on top of `icc` and `icpc`, which in turn may
// be wrappers built on top of `gcc` and `g++`.  Deltafs and its friends and
// dependencies can work with them.  The underlying gcc can be either 4.4+,
// 5.x, or 6.x.  C++11 is not required.
module load cmake  # v3.0 is required, the newer the better
module load boost
```






