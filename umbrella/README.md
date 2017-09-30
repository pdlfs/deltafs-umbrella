# PDLFS umbrella

PDLFS umbrella is an embeddable cmake-based framework for building
third party software.  It is designed to be embedded within other
projects as a git subrepo (https://github.com/ingydotnet/git-subrepo).
Note that only developers need to know that the umbrella is
a git subrepo.  Non-developers will see the umbrella as a
normal git directory and do not need to install git subrepo.

# usage

First you must embed umbrella in the repository you want to use
it then.  Once umbrella is embedded, you can use cmake to link
into it.

## embed umbrella (using git subrepo)

To embed PDLFS umbrella into a repository, you must first install
git subrepo (see URL above).   Then you check out your repository
and then use "git subrepo clone repo subdir" to embed umbrella within it.
Here is an example of embedding PDLFS umbrella inside the
deltafs-umbrella:

```
% cd deltafs-umbrella
% git subrepo clone git@dev.pdl.cmu.edu:pdlfs/umbrella umbrella
Subrepo 'git@dev.pdl.cmu.edu:pdlfs/umbrella' (master) cloned into 'umbrella'.
%
```

If you are an umbrella developer you can push and pull changes
from your repository to the umbrella repository.  For example,
to pull in the latest changes from the umbrella repository into
your repository you can use "git subrepo pull" like this:

```
% cd deltafs-umbrella
% git subrepo pull umbrella
Subrepo 'umbrella' pulled from 'git@dev.pdl.cmu.edu:pdlfs/umbrella' (master).
chuck@h0:/proj/TableFS/data/chuck/src/deltafs-umbrella % git status
On branch master
Your branch is ahead of 'origin/master' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working directory clean
% git push
```

Or, if you want to make a change to umbrella in your repository and
then push it to the umbrella repository you can use "git subrepo push"
like this:

```
% cd deltafs-umbrella
% vi umbrella/README.md
...
% git add umbrella/README.md
% git commit
% git push
% git subrepo push umbrella
```
