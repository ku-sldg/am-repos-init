# Theorem Scenario

## Steps

1) Copy files from `asp-libs/attacks/targ_files/theorem_demo/` to a path (here, we'll call it `<path_to_theorems_env_root>`)
1) Locate the am-cakeml repo folder (here, we'll call it `<path_to_am-cakeml>`)
1) Replace the `coqc` executable with one from your machine. 
   The currently used `coqc` is within `asp-libs/attacks/targ_files/theorem_demo/my_theorems_env/`,
   which within the copied files should be at `<path_to_theorem_env_root>/my_theorems_env/`.
   You can find your `coqc` executable using the command:
   ```
   which coqc
   ```

1) In `asp-libs/executables/goldenevidence_appr/src/main.rs` there currently is a hardcoded path on line 102.
   Replace the path up to your location of `am-cakeml` and remake using `make` at the root of your `asp-libs` repository.
   <!-- This is needed before running the protocol server-client. I don't know what other steps this is needed before yet. -->

1) Create the `concretized_args` folder:
   ```
   mkdir rust-am-clients/testing/asp_args/concretized_args
   ```
   <!-- This is needed before running concretize_args.py at the latest. -->
   
1) Create the environment variables `AM-CLIENTS-ROOT` and `AM-ROOT`. `AM-CLIENTS-ROOT` should be set to the root of your `rust-am-clients` repository, and `AM-ROOT` to the root of your `am-cakeml` repository.
   ```
   export AM-CLIENTS-ROOT = $(cd rust-am-clients; echo $PWD)
   export AM-ROOT = $(cd am-cakeml; echo $PWD)
   ```
   <!-- This is needed before running provisioning at the latest. -->
 
1) Concretize attestation ASP_ARGS for provisioning: 
    ```
    cd rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_provision_args_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_provision_args_concretized.json --params x=<path_to_theorems_env_root>
    ```
1) Run provisioning server:
    ```
    cd am-cakeml/tests/ &&
    make demo_theorem_provision_noclient
    ```
    
1) Run provisioning client (in a separate terminal!):
    ```
    cd rust-am-clients/ &&
    make am_client_run_theorem_test_provision
    ```
    You can safely ignore the Appraisal Summary output for provisioning...
1) Concretize attestation ASP_ARGS for protocol execution:
    ```
    cd rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_args_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_args_concretized.json --params x=<path_to_theorems_env_root>
    ```
1) Concretize appraisal ASP_ARGS for protocol execution:
    ```
    cd rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/run_theorem_test_args_appr_abstracted.json --outfile testing/asp_args/concretized_args/run_theorem_test_args_appr_concretized.json --params x=<path_to_am-cakeml>
    ```
1) Run protocol server:
    ```
    cd am-cakeml/tests/ &&
    make demo_theorem_noclient
    ```
    
1) Run protocol client (in a separate terminal!):
    ```
    cd rust-am-clients/ &&
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
