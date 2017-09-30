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
between the repositories.

