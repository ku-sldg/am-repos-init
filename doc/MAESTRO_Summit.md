# MAESTRO Summit Tutorial

Welcome to the MAESTRO Summit Tutorial! In what follows, we will walk through examples of MAESTRO usage, starting from simple pre-configured examples and moving toward more advanced, user-customized MAESTRO configurations.

MAESTRO (Measurement and Attestation Execution and Synthesis Toolkit for Remote Orchestration) is a collection of tools to support the specification, configuration, and execution of layered attestation protocols. A recent publication with a deeper dive into the conceptual ideas around MAESTRO can be found [here](https://dl.acm.org/doi/10.1007/978-3-031-77382-2_17). At the core of MAESTRO is a domain-specific-language for specifying attestation protocols called Copland. Throughout this tutorial we will introduce snippets of Copland by example. For a more thorough introduction see the original publication for Copland [here](https://link.springer.com/chapter/10.1007/978-3-030-17138-4_9) or more Copland resources at the [Copland website](https://copland-lang.org/).

## Getting Started (Installation)

In order to run the examples in this tutorial, you'll need to clone and build some MAESTRO artifacts. First, clone the `am-repos-init` repository and checkout the `maestro-summit` branch:

```sh
git clone https://github.com/ku-sldg/am-repos-init.git &&
cd am-repos-init &&
git checkout -b maestro-summit
```

Follow the instructions in that repo's [README.md](https://github.com/ku-sldg/am-repos-init/tree/maestro-summit) to install the tools (Quick Install) and test the install (Quick Test).

With the tools installed, we can run some example Copland protocols with the help of MAESTRO and observe their output.

We will assume for the rest of this tutorial that (per the Quick Install) your `AM_REPOS_ROOT` environment variable is set, and the MAESTRO repositories are configured as direct sub-directories -- `(am-cakeml/, asp-libs/, rust-am-clients/)`.

We'll start by running some simple protocols that stay local to one machine. For now, we will group all of the AM (Attestation Manager) servers and AM clients into one tmux session for convenience. Later we will launch server and client AMs independently, and ultimately demonstrate protocols that participate in cross-platform AM-to-AM communications (via TCP/IP).

### attest protocol (local)

The first protocol scenario is called `attest`. The Copland protocol term is a single ASP (Attestation Service Provider) term seen here in [Copland concrete syntax](https://ku-sldg.github.io/copland/resources/tutorial/README#:~:text=in%20the%20paper.-,Copland%20Syntax,-A%20symbol%20is):

```
*P0:  <attest  P0  sys_targ>
```

In summary, this syntax says: "At place `P0`, run the ASP `attest` to measure target `sys_targ` at place `P0`".

To run this protocol (`-t term` indicates the protocol term to run, `-s` indicates to only "send" the protocol, and NOT to do an Appraisal Summary):

```sh
cd $AM_REPOS_ROOT/am-cakeml/tests/ &&
./CI/Test.sh -t attest -s
```

Successful output looks like:

```
SUCCESS: Copland Phrase Executed Successfully!
```

If desired, scroll up on the tmux window to view selected outputs during protocol execution. Also, try switching tmux panes (towards the bottom of the terminal, there should be labels like 1:AM_0, 2:Client, ...) to see different AM servers outputs. Your mileage may vary here, tmux can be a bit finicky -- as an alternative, try running the above ./CI/Test.sh command with an extra `-h` option to run in "headless" mode -- i.e. without tmux.

To exit the tmux session and kill all running AMs, type `tmux kill-server` in any window.

Next, navigate to `am-cakeml/tests/DemoFiles/Generated/` to see the various (JSON) configuration files used to configure and run the `attest` protocol. In particular, see the protocol itself in `attest.json`, the Manifest for place `P0` in `Manifest_P0.json`, and the Attestation Session in `Full_Session.json`. The protocol and Manifest will be tailored specifically for the `attest` scenario, however the Attestation Session will have extra config items to support later scenarios. TIP: Open these JSON files in an editor that supports JSON formatting/syntax highlighting (we recommend VS-Code).

Looking briefly at the fields for the Manifest (`Manifest_P0.json`):

- `"ASPS"` contains a JSON Array of supported ASP_IDs (ASP Identifiers). In this case, it is a singleton array ["attest"].
- `"ASP_FS_MAP"` contains a JSON object of key/value pairs that maps ASP_IDs to their corresponding executable binary file system locations. When this value is empty, the default path assigned to the binary is $ASP_BIN/<ASP_ID>, where ASP_BIN is an environment variable pointing to the ASP executables, and <ASP_ID> is the ASP_ID mentioned in the `"ASPS"` field. So in this case, the "attest" ASP_ID would map to an executable at path: `$ASP_BIN/attest`. For this demo, $ASP_BIN defaults to: `$AM_REPOS_ROOT/asp-libs/target/release/`. The implementation for the "attest" binary is a rust source file located at: `$AM_REPOS_ROOT/asp-libs/executables/attest/src/main.rs`. Its [implementation](https://github.com/ku-sldg/asp-libs/blob/maestro-summit/executables/attest/src/main.rs) is quite simple, returning only "dummy" evidence: the string "attest". The implementation is further simplified by leveraging the Copland-specific library function `handle_body` from the common rust-am-lib repository [here](https://github.com/ku-sldg/rust-am-lib/blob/045e9c65d81761cc09743f487f8053de996050ee/src/copland.rs#L458). We will revisit ASP implementations later in more detail.
- `"Policy"` is related to evidence disclosure, but is left unimplemented for this demo.

Finally, looking at the fields for the Attestation Session (`Full_Session.json`):

- `"Plc_Mapping"` tells protocol participants how to map PLC_IDs (Place identifiers) to UUID strings that capture concrete AM addresses (with format: "`<IP>:<PORT>`"). For instance, `"P0": "127.0.0.1:5000"` says that place `"P0"` maps to port 5000 on localhost (127.0.0.1).
- `"Sesion_Context": {"ASP_Types":  ` informs the evidence bundling procedure (internal to each AM) how each ASP consumes and produces new raw evidence. In summary, the ASP_Type specification for "attest" says that "attest" should consume all input evidence (`"EvInSig": "ALL"`), and extend the evidence bundle by one value (`"EXTEND", ... "OutN", ... "1"`).
- `"Sesion_Context": {"ASP_Comps"` indicates a "compatibility map" for ASPs, mapping attestation ASP_IDs to corresponding appraisal ASP_IDs. These are not strictly necessary for this "attest" protocol scenario because it does not yet include the Copland appraisal primitive (`APPR`).
- `"PubKey_Mapping"` tells protocol participants how to map PLC_IDs to public key strings (used for cryptographic operations like checking signatures, encryption).

### cert protocol (local)

Next, we'll move to a slightly more complex protocol scenario, albeit still local to one machine. The Copland syntax for the `cert` protocol is as follows:

```
*P0:
    @P1 [ <attest P1 sys_targ> ->
          @P2 [ <appraise P2 sys_targ> ->
                <certificate P2 sys_targ> ]
        ]
```

Conceptually, this protocol involves collecting evidence at place `P1` (via `attest`), then sending that evidence to place `P2` to be appraised (via `appraise`) and finally certified (via `certificate`). For simplicity, `appraise` and `certificate` are implemented as dummy measurements similar to `attest` that return dummy values "appraise" and "certificate", respectively.

To run this protocol, from `am-cakeml/tests/`, run:

```sh
./CI/Test.sh -t cert -s
```

Notice in the output that the resulting Raw Evidence is a sequence of three values (representing the base64 representations of the "attest", "appraise", and "certificate" strings):

```
"...PAYLOAD":{"RAWEV":{"RawEv":["Y2VydGlmaWNhdGU=","YXBwcmFpc2U=","YXR0ZXN0"]}...
```

### attest protocol (local, standalone AM server)

We will now revisit the `attest` protocol scenario, but instead of launching the AM server and client from the same terminal, we will configure and run the server executable in a separate (but still local) terminal session.

For convenience, all relevant AM server configuration files can be found in `$AM_REPOS_ROOT/am-cakeml/am_configs/`. Each protocol scenario has its own sub-directory there.

To start the AM server for place `P0` in the `attest` scenario, open a new terminal and navigate to `$AM_REPOS_ROOT/am-cakeml/`. Then run the following command:

```sh
 ./build/bin/attestation_manager -m $AM_REPOS_ROOT/am-cakeml/am_configs/attest/Manifest_P0.json -u 127.0.0.1:5000 -b $AM_REPOS_ROOT/asp-libs/target/release/ --comms $AM_REPOS_ROOT/rust-am-clients/target/release/rust-am-comms-client
```

NOTE: There is a convenience script called `start_am_server.sh` in `$AM_REPOS_ROOT/am-cakeml/am_configs/` that simplifies starting servers. However it requires first setting the following environment variables (TIP: add these to your terminal startup script to avoid setting these for each new terminal session):

```sh
export AM_ROOT=$AM_REPOS_ROOT/am-cakeml/ &&
export ASP_BIN=$AM_REPOS_ROOT/asp-libs/target/release/ &&
export AM_COMMS_BIN=$AM_REPOS_ROOT/rust-am-clients/target/release/rust-am-comms-client
```

With these variables set, the command to start the `attest` AM server from `$AM_REPOS_ROOT/am-cakeml/am_configs/` becomes:

```sh
./start_am_server.sh -m attest/Manifest_P0.json -u 127.0.0.1:5000
```

Now that the AM server is running and listening for requests, open up a separate terminal and navigate to `$AM_REPOS_ROOT/rust-am-clients/`. Then run:

```sh
make am_client_attest
```

If successful, this will show activity in the AM server terminal at 127.0.0.1:5000 and also print protocol results in the client AM terminal. Successful client output will end with:

```
ProtocolRunResponse { TYPE: "RESPONSE", ACTION: "RUN", SUCCESS: true, PAYLOAD: Evidence { RAWEV: RawEv(["YXR0ZXN0"]), EVIDENCET: asp_evt("P0", ASP_PARAMS { ASP_ID: "attest", ASP_ARGS: Object {}, ASP_PLC: "P0", ASP_TARG_ID: "sys_targ" }, mt_evt) } }
```

Uner the hood, this make target runs the `rust-am-client` executable (`cargo run --release --bin rust-am-client`) with parameters to specify the client protocol (`-t`), protocol session (`-a`) and AM server where the protocol is sent (`-s`). In this case, we pass the same protocol and session from `$AM_REPOS_ROOT/am-cakeml/am_configs/attest/`, and specify `127.0.0.1:5000` as the destination server UUID.

See `$AM_REPOS_ROOT/rust-am-clients/Makefile` for specific parameters passed to client make targets. For a description of all command line options for `rust-am-client`, type: `make am_client_help`.

### cert protocol (local, standalone AM servers)

With the AM server for the `attest` scenario still running, try running the following from the client terminal:

```sh
make am_client_cert
```

Notice that this fails at the AM server soon after the following output:

```
Trying to connect to server at address:  127.0.0.1:5001 from ...
```

Recall that the `cert` protocol scenario expects AM servers running at `127.0.0.1:5001` (to run the `attest` ASP), and at `127.0.0.1:5002` (to run the `appraise` and `certificate` ASPs). When we ran `make am_client_cert`, the AM server at port `127.0.0.1:5000` received the protocol request, but failed in its attempt to reach the (non-existent) AM server at `127.0.0.1:5001`.

To remedy this, open up two new terminals and in each navigate to `$AM_REPOS_ROOT/am-cakeml/am_configs/`. In one, run:

```sh
./start_am_server.sh -m cert/Manifest_P1.json -u 127.0.0.1:5001
```

And in the other, run:

```sh
./start_am_server.sh -m cert/Manifest_P2.json -u 127.0.0.1:5002
```

NOTE: The AM server at port `5000` should still be running, and is sufficiently configured to handle the `cert` protocol (all it needs to know is how to contact Place `P1`, which it receives in the Attestation Session configured by the client AM).

With the three server AMs running at ports `5000`, `5001`, and `5002`, from the client terminal try running again:

```sh
make am_client_cert
```

Successful output looks like:

```
ProtocolRunResponse { TYPE: "RESPONSE", ACTION: "RUN", SUCCESS: true, PAYLOAD: Evidence { RAWEV: RawEv(["Y2VydGlmaWNhdGU=", "YXBwcmFpc2U=", "YXR0ZXN0"]) ...
```

### cert protocol + APPR (local, standalone AM servers)

Next, we extend the `cert` protocol to perform automatic appraisal via the Copland APPR primitive. The new `cert_appr` protocol phrase is as follows:

```
*P0:
    @P1 [ <attest P1 sys_targ> ->
          @P2 [ <appraise P2 sys_targ> ->
                <certificate P2 sys_targ> ]
        ] ->
    <APPR>
```

This is identical to the `cert` phrase, but with a trailing `<APPR>` term. Note that due to scoping, this `<APPR>` happens at place `P0`. The `<APPR>` primitive is quite powerful and is defined generally over all Copland phrases. In this specific `cert_appr` phrase, it (the AM at place `P0`) must be prepared to appraise evidence produced by all the ASPs preceding `<APPR>`: `attest`, `appraise`, `certificate`. The mechanism to tell `<APPR>` how to appraise evidence produced by specific ASPs is the `Session_Context": "ASP_Comps"` field of the Attestation Session. For the `cert_appr` scenario, this field is as follows:

```
"ASP_Comps": {
    "attest": "magic_appr",
    "certificate": "magic_appr",
    "appraise": "magic_appr",
    ...
```

`magic_appr` is a "dummy" appraisal ASP that consumes any input evidence and returns an empty evidence value (the empty string "").

Let's now configure and run the `cert_appr` scenario in our local terminals. In the same terminals as before in the `cert` scenario, run each of the following commands:

```sh
./start_am_server.sh -m cert_appr/Manifest_P0.json -u 127.0.0.1:5000
```

```sh
./start_am_server.sh -m cert_appr/Manifest_P1.json -u 127.0.0.1:5001
```

```sh
./start_am_server.sh -m cert_appr/Manifest_P2.json -u 127.0.0.1:5002
```

And finally, from the client terminal, run:

```sh
make am_client_cert_appr
```

Notice at the beginning of the output, the results of `magic_appr` on each of the pieces of primitive ASP evidence:

```
ProtocolRunResponse { ... PAYLOAD: Evidence { RAWEV: RawEv(["", "", ""]) ... }
```

For a more consice "Appraisal Summary", try running the following client make target (same as before but the the `-m` option for Appraisal Summary):

```sh
make am_client_cert_appr_appsumm
```

An Appraisal Summary will walk the Copland evidence structure and look for the "good" evidence value (in this case the empty string ""). The output will end with a pretty-printed Appraisal Summary that prints "PASSED" if appraisal succeeds on each target.

### Delegated Appraisal (`cert` + `<APPR>`)

An alternative strategy for performing appraisal is to delegate appraisal to a dedicated AM server. This leads to (effectively) running two separate attestation sessions in sequence as follows:

```
E <- (*P0[]:
         @P1 [ <attest P1 sys_targ> ->
             @P2 [ <appraise P2 sys_targ> ->
                   <certificate P2 sys_targ> ]
             ]
    ) ;;
*P0[E]: <APPR>
```

Evidence from the `cert` phrase (executed at `P0`) is passed to the "appraisal server AM" (in this case, also `P0`) for appraisal. The notation `*P0[E]:` means initiate a session with place `P0` with "initial evidence" `E`. The evidence structure `E` contains both raw evidence and meta-evidence indicating how the evidence was collected (ASPs used, measurement targets, etc.). NOTE: the above syntax is still "pseudo-Copland" at the time of writing.

To run the `cert` + `<APPR>` delegated appraisal (using the same server AMs as for `cert_appr`):

```sh
make am_client_cert_appr_delegated
```

This make target includes additional parameters to indicate the appraisal server AM (`-r`) and appraisal ASP_ARGS (`-d`). ASP_ARGS provide a way to customize Copland protocols for specific measurement "targets" (we will see examples of this later in this tutorial). Because the ASPs for `cert` are all "dummy" versions that produce static strings, its ASP_ARGS are simply the empty JSON object (`{}`) (both for its attestation AND appraisal ASPs -- recall that `magic_appr` is also a dummy implementation).

### attest protocol (remote AM servers)

Next, we will run a new version of the attest protocol, called `attest_remote`, that makes a remote request across a machine boundary:

```
*P0:  @P1 [ <attest  P1  sys_targ> ]
```

Before running this protocol, we must configure the server AMs for place `P0` and `P1`. `P0` can remain local, and we can start it with the same configuration as the `cert_appr` protocol:

```sh
./start_am_server.sh -m cert_appr/Manifest_P0.json -u 127.0.0.1:5000
```

To configure `P1`, first switch machines then start the `P1` server as before:

```sh
./start_am_server.sh -m cert_appr/Manifest_P1.json -u 127.0.0.1:5001
```

In a separate terminal on the remote machine, determine the machine's IP address (try the `ifconfig` command line utility or go to network settings). Record (or copy) the IP address, we will refer to it as `<REMOTE_IP>`.

Back on the local machine, in the client AM terminal, navigate to the client-side attestation sessions and copy the existing session file for `cert_appr` to a new file:

```sh
cd $AM_REPOS_ROOT/rust-am-clients/testing/attestation_sessions/ &&
cp session_cert_appr.json session_attest_remote.json
```

Next, copy and tweak the rust-am-clients make target for `am_client_attest` to point to the new `attest_remote` protocol (found at `testing/protocols/noargs/protocol_attest_remote_noargs.json`) and the newly created session. The new make target should look something like this:

```
am_client_attest_remote:
	cargo run --release --bin rust-am-client -- -t $(PROTOCOLS_DIR)protocol_attest_remote_noargs.json -a $(SESSIONS_DIR)session_attest_remote.json -s 127.0.0.1:5000
```

NOTE: the top-level AM server can remain local (`-s`) since the `@P1` portion of the protocol will handle the remote communication.

Finally, edit the new session file to associate place `P1` with the remote machine's IP. This will amount to replacing one line as follows:

```
"P1": "127.0.0.1:5001",

==>

"P1": "<REMOTE_IP>:5001",
```

With both AM servers running (`P0` locally, `P1` remotely), run the client AM:

```
make am_client_attest_remote
```

Assuming firewalls on the remote machine are configured properly, the protocol will run as expected, with activity on both AM servers and one evidence value returned to the client AM.

### Exercise: multi-node attest protocol (remote AM servers)

As an exercise, configure and run the following protocol:

`attest_remote_multinode` :=

```
*P0:  (@P1 [ <attest  P1  sys_targ> ]) +<+
      (@P2 [ <attest  P2  sys_targ> ])
```

Where the server AMs for places `P0`, `P1`, and `P2` are running on separate machines with distinct IP addresses.

Use the steps for the above `attest_remote` protocol scenario as a guide. HINT: You will need to ensure that 1) The attestation session maps `P1` and `P2` to their remote IPs and 2) the Manifests for the remote AMs minimally include the `attest` ASP_ID.
