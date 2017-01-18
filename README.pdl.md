**// This file is for PDL internal developers**

[![Build Status](https://travis-ci.org/pdlfs/deltafs-umbrella.svg?branch=master)](https://travis-ci.org/pdlfs/deltafs-umbrella)

# deltafs-umbrella

Download, build, and install deltafs, deltafs friends, and their dependencies in a single highly-automated step.

All pdlfs repositories are mirrored at both github.com and one pdlfs-internal git server running at dev.pdl.cmu.edu.

Specific to deltafs-umbrella, we have also used a service known as git-lfs to efficiently track large binary files
to help us reduce the overhead of maintaining those big things within our repository.
These large binary files are typically compressed tar files of many deltafs external dependencies.

**The purpose of this guild to show fellow pdlfs internal developers the steps of
properly setting up the repository and syncing the mirrors at both github.com and dev.pdl.cmu.edu.**

## Install git-lfs client

```
// First, get latest git-lfs from https://git-lfs.github.com/
// The latest version may be higher than 1.5.3.
//
// For example, on 64-bit Ubuntu:
wget https://github.com/git-lfs/git-lfs/releases/download/v1.5.3/git-lfs-linux-amd64-1.5.3.tar.gz
tar xzf git-lfs-linux-amd64-1.5.3.tar.gz -C .

cd git-lfs-1.5.3

sudo ./install.sh

// Second and optionally, add a convenient git-lfs config
git config --global --add lfs.skipdownloaderrors true
```

## Local repository setup guide

We will use dev.pdl.cmu.edu as our primary git repository, and github.com as our secondary repository.
For git-lfs, however, both will use the service provided by github.com.
This ensures our external collaborators can `git-lfs pull` files without knowing the existence of dev.pdl.cmu.edu. 

Here, it is assumed that git-lfs has been installed.

```
// First, git-clone from dev.pdl.cmu.edu but avoid fetching
// any git-lfs files because this will fail anyway
git lfs clone --exclude="cache.0" git@dev.pdl.cmu.edu:pdlfs/deltafs-umbrella.git

cd deltafs-umbrella

// install git lfs for the repository (if you haven't globally enabled it)
git lfs install --local

// Secondly, config git-lfs to use github.com as the service provider,
// which by default will be dev.pdl.cmu.edu
git config --add lfs.url git@github.com:pdlfs/deltafs-umbrella.git
git config --add lfs.pushurl git@github.com:pdlfs/deltafs-umbrella.git

// Next and optionally, fetch all git-lfs files
git lfs pull

// Finally, add a push alias "all" that pushes to both dev.pdl and github
git remote add all git@github.com:pdlfs/deltafs-umbrella.git
git remote set-url --add --push all git@dev.pdl.cmu.edu:pdlfs/deltafs-umbrella.git
git remote set-url --add --push all git@github.com:pdlfs/deltafs-umbrella.git

// verify settings
git remote -v

```
