# Theorem Scenario

## Installation

Follow the steps at the link below for installing and building the necessary MAESTRO repos (**IMPORTANT**:  During that setup, make sure to clone the `theorem-scenario` branch for all repos (including this am-repos-init repo), e.g.:

```sh
git clone -b theorem-scenario https://github.com/ku-sldg/am-repos-init.git
```
```sh
cd am-repos-init &&
./configure.sh -b theorem-scenario
```

The `-b` option tells our `./configure` script to check out the `theorem-scenario` branch for each MAESTRO repo.

Ok, here's the link:  [MAESTRO Repos Quick Install](https://github.com/ku-sldg/am-repos-init/blob/theorem-scenario/README.md).

## Theorem Attestation Scenario (Description)

The goal of the Theorem Attestation Scenario is to use the MAESTRO toolchain to provision, gather, and appraise Copland evidence bundles that bolster confidence in outputs of theorem proving tools.  In this document we walk through an example that is tailored to the Coq theorem prover, but we intend to generalize this mechanism to other provers in the near future.

This scenario consists of two Coq source files (with extension .v) called ImportantTheorem.v and ImportantTheoremTest.v.  ImportantTheorem.v states and proves an "important" simple property about boolean AND (`andb true true = true` in Coq).  ImportantTheoremTest.v is a "test harness" for this theorem.  It checks that 1) the theorem has the correct type (it proves the intended theorem) and 2) the proof of the theorem does not introduce and Axioms.  

The attestation protocol will A) attest to the environment these proofs were run in (check for a legitimate `coqc` executable and `ImportantTheoremTest.v` source file) and B) utilize the Coq compiler (`coqc`) to compile both .v source files and observe their output.  A provisioning protocol allows us to establish a golden evidence tree with "expected values" for steps A) and B) in the protocol.  This provisioned evidence is used during appraisal to make judgements about the target (`ImportantTheorem.v`) and its environment (`coqc` and `ImportantTheoremTest.v`).

## Steps to configure and run Theorem Attestation Scenario

These steps will assume you've completed the [Installation](#Installation) steps from above, and thus have cloned and built the MAESTRO github repositories at the following directory structure: 

```sh
<path-to-am_repos_root>/

    -- am-cakeml/
    -- asp-libs/
    -- rust-am-clients/
```

1) Set a handful of additional environment variables:

    ```sh
    export AM_REPOS_ROOT=<path-to-am_repos_root> &&
    export AM_CLIENTS_ROOT=$AM_REPOS_ROOT/rust-am-clients &&
    export AM_ROOT=$AM_REPOS_ROOT/am-cakeml &&
    export ASP_BIN=$AM_REPOS_ROOT/asp-libs
    ```

    RECOMMENDED:  For maximum convenience (to avoid re-setting these across different terminal sessions) add these exports to your global .bashrc file (or equivalent for your platform).

1) Create a new directory (we'll call it `$THEOREM_DEMO_ROOT`), and copy to it all files (and directories) from `$AM_REPOS_ROOT/asp-libs/attacks/targ_files/theorem_demo/` 

    ```sh
    mkdir my_theorem_demo && 
    cp -r $AM_REPOS_ROOT/asp-libs/attacks/targ_files/theorem_demo/* my_theorem_demo/

    ```

    RECOMMENDED:  Set `$THEOREM_DEMO_ROOT` as an environment variable to allow copy/paste of later commands in this document:

    ```sh
    export THEOREM_DEMO_ROOT=<path-to-my_theorem_demo>/my_theorem_demo/
    ```


1) If you have Coq installed on your system, locate your `coqc` executable file (`which coqc`), otherwise first install it.  For maximum stability, we recommend following the steps [here](https://github.com/ku-sldg/copland-avm?tab=readme-ov-file#build-instructions) to install a particular [fork+branch](https://github.com/ku-sldg/coq/tree/cakeml-extraction) of Coq we have tested against the Coq source files used in this demo.

1) Move the `coqc` executable to `$THEOREM_DEMO_ROOT/my_theorems_env/` :
    ```sh
    cp <your-path-to-coqc>/coqc $THEOREM_DEMO_ROOT/my_theorems_env/
    ```
1) Create a directory called `concretized_args` at the following path(the files added here will be specific to your machine, and thus excluded from git history automatically via the .gitignore):
    ```sh
    mkdir $AM_REPOS_ROOT/rust-am-clients/testing/asp_args/concretized_args
    ```

1) Concretize attestation ASP_ARGS for provisioning: 
    ```sh
    cd $AM_REPOS_ROOT/rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_provision_args_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_provision_args_concretized.json --params x=$THEOREM_DEMO_ROOT
    ```
1) Run provisioning server (NOTE:  This will start a `tmux` terminal session with the necessary Attestation Manager server running.  To kill all servers, type `tmux kill-server` in any of the tmux windows).
    ```sh
    cd $AM_REPOS_ROOT/am-cakeml/tests/ &&
    make demo_theorem_provision_noclient
    ```
1) Open a separate terminal window (now for the client), export necessary environment variables:
    ```sh
    export AM_REPOS_ROOT=<path-to-am_repos_root> &&
    export AM_CLIENTS_ROOT=$AM_REPOS_ROOT/rust-am-clients &&
    export AM_ROOT=$AM_REPOS_ROOT/am-cakeml
    export THEOREM_DEMO_ROOT=<path-to-my_theorem_demo>/my_theorem_demo/
    ```
   
1) In the new terminal, now run the provisioning client:
    ```sh
    cd $AM_REPOS_ROOT/rust-am-clients/ &&
    make am_client_run_theorem_test_provision
    ```
    You can safely ignore any "Appraisal Summary" output for provisioning.
1) Concretize attestation ASP_ARGS for protocol execution (IMPORTANT: make sure you run this in a terminal with `$THEOREM_DEMO_ROOT` set!):
    ```sh
    cd $AM_REPOS_ROOT/rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_args_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_args_concretized.json --params x=$THEOREM_DEMO_ROOT
    ```
1) Concretize appraisal ASP_ARGS for protocol execution:
    ```sh
    cd $AM_REPOS_ROOT/rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_args_appr_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_args_appr_concretized.json --params x=$AM_ROOT
    ```
1) Run protocol server (if the provisioning server is still running, type `tmux kill-server` anywhere in a tmux window):
    ```sh
    cd $AM_REPOS_ROOT/am-cakeml/tests/ &&
    make demo_theorem_noclient
    ```
1) In the client terminal, run the protocol client:
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
