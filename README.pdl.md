**This file is for pdlfs internal developers**

# deltafs-umbrella

Download, build, and install deltafs, deltafs friends, and their dependencies in a single highly-automated step.

All pdlfs repositories are mirrored at both github.com and one pdlfs-internal git server running at dev.pdl.cmu.edu.

Specific to deltafs-umbrella, we have also used a service known as git-lfs to efficiently track large binary files
to help us reduce the overhead of maintaining those big things within our repository.
These large binary files are typically compressed tar files of many deltafs external dependencies.

**The purpose of this guild to show fellow pdlfs internal developers the steps of
properly setting up the repository and syncing the mirrors at both github.com and dev.pdl.cmu.edu.**

## Install git-lfs client

**// still work-in-progress**

## Local repository setup guide

We will use dev.pdl.cmu.edu as our primary git repository, and github.com as our secondary repository.
For git-lfs, however, both will use the service provided by github.com.
This ensures our external collaborators can `git-lfs pull` files without knowing the existence of dev.pdl.cmu.edu. 

```
// First, git-clone from dev.pdl.cmu.edu but avoid fetching
// any git-lfs files because this will fail anyway
git lfs clone --exclude="cache.0" git@dev.pdl.cmu.edu:pdlfs/deltafs-umbrella.git

cd deltafs-umbrella

// Secondly, config git-lfs to use github.com as the service provider,
// which by default will be dev.pdl.cmu.edu
git config --add lfs.url git@github.com:pdlfs/deltafs-umbrella.git
git config --add lfs.pushurl git@github.com:pdlfs/deltafs-umbrella.git

// Last and optionally, fetch all git-lfs files
git lfs pull
```
