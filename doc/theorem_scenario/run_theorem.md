# Theorem Scenario

## Steps

1) Copy files from `asp-libs/attacks/targ_files/theorem_demo/` to a path (here, we'll call it `<path_to_theorems_env_root>`)
1) Replace the `coqc` executable with one from your machine 
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
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/testing/asp_args/placeholder_args/run_theorem_test_args_abstracted.json --outfile testing/asp_args/concretized_args/testing/asp_args/placeholder_args/run_theorem_test_args_concretized.json --params x=<path_to_theorems_env_root>
    ```
1) Concretize appraisal ASP_ARGS for protocol execution:
    ```
    cd rust-am-clients &&
    python3 scripts/concretize_args.py --infile testing/asp_args/placeholder_args/testing/asp_args/placeholder_args/run_theorem_test_args_appr_abstracted.json --outfile testing/asp_args/concretized_args/testing/asp_args/placeholder_args/run_theorem_test_args_appr_concretized.json --params x=<path_to_theorems_env_root>
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
