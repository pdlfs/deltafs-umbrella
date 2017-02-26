# Job scripting guidelines

- Prefer simple math. `$((8 * (2**20)))` is easier to parse than `8388608`.

- Avoid `/dev/urandom`. It is prohibitively slow once entropy is exhausted.

- Create a per-job directory in a globally mounted volume (e.g., Lustre) to
  hold your experiment output (and temporary data; avoid using `/tmp`).
  Prefer one file per writer to avoid buffering/ordering issues.

- Consider the implications of `stdout` and `stderr` carefully, and redirect
  with care. Prefer to log all errors and data, but only print errors that the
  script user can fix (e.g., usage, syntax).

- Use `do_mpirun` ([common.sh](common.sh#L131)) instead of invoking mpirun
  yourself. It will invoke aprun, mpirun.mpich, or mpirun.openmpi. Whichever is
  available will preferred, in that order.

- If you need to produce a hostfile with all available hostnames, use
  `gen_hostfile` ([common.sh](common.sh#L12)). It will store the hostfile in
  `$job_dir/hosts.txt` and populate a variable `all_nodes` with its contents.

- `message` is used to output a message to the user, while also logging it.
  `die` will print and log a message, and terminate the job with an error.

