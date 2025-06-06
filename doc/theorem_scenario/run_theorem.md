# Theorem Scenario

## Installation

Follow the steps [here](https://github.com/ku-sldg/am-repos-init/blob/theorem-scenario/README.md) for installing and building the necessary MAESTRO repos.

IMORTANT:  During that setup, make sure to clone the `theorem-scenario` branch for all repos (including this am-repos-init repo), e.g.:

```sh
    git clone -b theorem-scenario https://github.com/ku-sldg/am-repos-init.git
```
```sh
    cd am-repos-init &&
    ./configure.sh -b theorem-scenario
```

The `-b` option tells ./configure to check out the `theorem-scenario` branch for each repo.



## Steps to run Theorem Scenario attestation

These steps will assume you've completed the installation steps from above, and thus have the $AM_REPOS_ROOT environment variable set to a common root directory above the MAESTRO repositories (am-cakeml, asp-libs, rust-am-clients).

1) Create a new directory (we'll call it `$THEOREM_DEMO_ROOT`), and copy to it all files (and directories) from `$AM_REPOS_ROOT/asp-libs/attacks/targ_files/theorem_demo/` 

    ```sh
    mkdir my_theorem_demo && 
    cp -r $AM_REPOS_ROOT/asp-libs/attacks/targ_files/theorem_demo/* my_theorem_demo/

    ```

    HINT:  set `$THEOREM_DEMO_ROOT` as an environment variable to allow copy/paste of later commands in this document:

    ```sh
    export THEOREM_DEMO_ROOT=<my_theorem_demo_path>
    ```


1) If you have Coq installed on your system, Locate your `coqc` executable file (`which coqc`), otherwise first install it [here](https://rocq-prover.org/install).
1) Move the `coqc` executable to `$THEOREM_DEMO_ROOT/my_theorems_env/` :
    ```sh
    cp coqc $THEOREM_DEMO_ROOT/my_theorems_env/
    ```
1) Create a directory called `concretized_args` at the following path(the files added here will be specific to your machine, and thus excluded from git history automatically via the .gitignore):
    ```sh
    mkdir $AM_REPOS_ROOT/rust-am-clients/testing/asp_args/concretized_args
    ```

1) Create the environment variables `AM_CLIENTS_ROOT` and `AM_ROOT`. `AM_CLIENTS_ROOT` should be set to the root of your `rust-am-clients` repository, and `AM_ROOT` to the root of your `am-cakeml` repository.
   ```sh
   export AM_CLIENTS_ROOT = $AM_REPOS_ROOT/rust-am-clients &&
   export AM_ROOT = $AM_REPOS_ROOT/am-cakeml
   ```

1) Concretize attestation ASP_ARGS for provisioning: 
    ```sh
    cd $AM_REPOS_ROOT/rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_provision_args_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_provision_args_concretized.json --params x=$THEOREM_DEMO_ROOT
    ```
1) Run provisioning server:
    ```sh
    cd $AM_REPOS_ROOT/am-cakeml/tests/ &&
    make demo_theorem_provision_noclient
    ```
1) In a separate terminal (NOTE: you will need to set the `$AM_REPOS_ROOT` environment variable in this new terminal), run the provisioning client:
    ```sh
    export AM_REPOS_ROOT=<path-to-am_repos_root> &&
    cd $AM_REPOS_ROOT/rust-am-clients/ &&
    make am_client_run_theorem_test_provision
    ```
    You can safely ignore any "Appraisal Summary" output for provisioning.
1) Concretize attestation ASP_ARGS for protocol execution:
    ```sh
    cd $AM_REPOS_ROOT/rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_args_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_args_concretized.json --params x=$THEOREM_DEMO_ROOT
    ```
1) Concretize appraisal ASP_ARGS for protocol execution:
    ```sh
    cd rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_args_appr_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_args_appr_concretized.json --params x=$AM_ROOT
    ```
1) Run protocol server:
    ```sh
    cd $AM_REPOS_ROOT/am-cakeml/tests/ &&
    make demo_theorem_noclient
    ```
1) In a separate terminal, run protocol client:
    ```sh
    cd $AM_REPOS_ROOT/rust-am-clients/ &&
    make am_client_run_theorem_test
    ```

Successful output should look something like:

```
---------------------------------------------------------------
Appraisal Summary: PASSED


goldenevidence_appr:
	run_coq_theorem_targ: PASSED
	run_coq_theorem_test_targ: PASSED
	coq_env_dir_targ: PASSED
---------------------------------------------------------------
```

Re-run provisioning (Steps 7 and 8) only when files in `$THEOREM_DEMO_ROOT/my_theorems_env/` must change.

## "Attacks" on Theorem Scenario

See attack/repair scripts in `$AM_REPOS_ROOT/asp-libs/attacks/theorem_attacks/` .  Observe the output (Appraisal Summary) of running the attestation client after each attack/repair.
