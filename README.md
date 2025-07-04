# am-repos-init
Initialization scripts for quick installation of am (Attestation Manager) repos (repositories) and their dependencies.

## Quick Install

Dependencies:
* Rust (https://www.rust-lang.org/tools/install)
* git
* More dependencies later (during manual configuration of the am-cakeml repo)

Steps:
1. Create a new directory (referred to below as `<path-to-am_repos_root>`).  This will serve as a common directory path at which varioius github repository dependencies will be cloned.
1. Set the `AM_REPOS_ROOT` environment variable to point to that newly-created directory:
    ```
        export AM_REPOS_ROOT=<path-to-am_repos_root>
    ```  
1. Run the `configure.sh` script:
    ``` 
        sh ./configure.sh
    ```
    This will clone specific branches of 3 repositories (am-cakeml, asp-libs rust-am-clients) from the [ku-sldg](https://github.com/orgs/ku-sldg/repositories) github repositories and place them at `<path-to-am_repos_root>/(am-cakeml, asp-libs rust-am-clients)`.  It will also attempt to build asp-libs and rust-am-clients automatically -- these should succeed given a good Rust/cargo environment is present.
1. Navigate to `<path-to-am_repos_root>/am-cakeml/` and follow the instructions in `README.md` to manually install the am-cakeml tools (and their dependencies).

## Quick Test

After completing the steps above in [Quick Install](#markdown-header-Quick-install), test a successfull installation by building and running the CI test suite in `<path-to-am_repos_root>/am-cakeml/`:
```
    cd <path-to-am_repos_root>/am-cakeml/tests/ &&
    make ci_build &&
    make ci_test
```

Successful output of the test suite will end with something like:

```
SUCCESS: Copland Phrase Executed Successfully!

Killing background processes...
```
