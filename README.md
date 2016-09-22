# deltafs-umbrella

Download and build deltafs and its dependencies in a single step.

Requirements: a compiler with standard build tools ("make"), internet
access to github.com, git, autotools, and cmake (3.0 or newer).

To build deltafs and install it in a directory (e.g. /tmp/deltafs):

```
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/tmp/deltafs ..
make
```
