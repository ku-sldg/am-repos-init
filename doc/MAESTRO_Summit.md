# MAESTRO Summit Tutorial

Welcome to the MAESTRO Summit Tutorial!  In what follows, we will walk through examples of MAESTRO usage, starting from simple pre-configured examples and moving toward more advanced, user-customized MAESTRO configurations.

MAESTRO (Measurement and Attestation Execution and Synthesis Toolkit for Remote Orchestration) is a collection of tools to support the specification, configuration, and execution of layered attestation protocols.  A recent publication with a deeper dive into the conceptual ideas around MAESTRO can be found [here](https://dl.acm.org/doi/10.1007/978-3-031-77382-2_17).  At the core of MAESTRO is a domain-specific-language for specifying attestation protocols called Copland.  Throughout this tutorial we will introduce snippets of Copland by example.  For a more thorough introduction see the original publication for Copland [here](https://link.springer.com/chapter/10.1007/978-3-030-17138-4_9) or more Copland resources at the [Copland website](https://copland-lang.org/).      

## Getting Started (Installation)

In order to run the examples in this tutorial, you'll need to clone and build some MAESTRO artifacts.  First, clone the `am-repos-init` repository and checkout the `maestro-summit` branch:

```
git clone https://github.com/ku-sldg/am-repos-init.git &&
cd am-repos-init &&
git checkout -b maestro-summit
```

Follow the instructions in that repo's [README.md](https://github.com/ku-sldg/am-repos-init/tree/maestro-summit) to install the tools (Quick Install) and test the install (Quick Test).

With the tools installed, we can run some example Copland protocols with the help of MAESTRO and observe their output.  

We will assume for the rest of this tutorial that your `AM_REPOS_ROOT` environment variable is set to a path we'll refer to as `<AM_REPOS_ROOT>`, and the MAESTRO repositories are configured as direct sub-directories -- `(am-cakeml/, asp-libs/, rust-am-clients/)` -- per the earlier installation.

We'll start by running some simple protocols that stay local to one machine.  For now, we will group all of the AM (Attestation Manager) servers and AM clients into one tmux session for convenience.  Later we will launch server and client AMs independently, and ultimately demonstrate protocols that participate in cross-platform AM-to-AM communications (via TCP/IP).

### attest protocol (local)

The first protocol scenario is called `attest`.  The Copland protocol term is a single ASP (Attestation Service Provider) term seen here in [Copland concrete syntax](https://ku-sldg.github.io/copland/resources/tutorial/README#:~:text=in%20the%20paper.-,Copland%20Syntax,-A%20symbol%20is):

```
*P0:  <attest  P0  sys_targ>
```

In summary, this syntax says:  "At place `P0`, run the ASP `attest` to measure target `sys_targ` at place `P0`".

To run this protocol (`-t term` indicates the protocol term to run, `-s` indicates to only "send" the protocol, and NOT to do an Appraisal Summary):

```
cd <AM_REPOS_ROOT>/am-cakeml/tests/ &&
./CI/Test.sh -t attest -s
```

Successful output looks like:
```
SUCCESS: Copland Phrase Executed Successfully!
```
If desired, scroll up on the tmux window to view selected outputs during protocol execution.  Also, try switching tmux panes (towards the bottom of the terminal, there should be labels like 1:AM_0, 2:Client, ...) to see different AM servers outputs.  Your mileage may vary here, tmux can be a bit finicky -- as an alternative, try running the above ./CI/Test.sh command with an extra `-h` option to run in "headless" mode -- i.e. without tmux.

To exit the tmux session and kill all running AMs, type `tmux kill-server` in any window.

Next, navigate to `am-cakeml/tests/DemoFiles/Generated/` to see the various (JSON) configuration files used to configure and run the `attest` protocol.  In particular, see the protocol itself in `attest.json`, the Manifest for place `P0` in `Manifest_P0.json`, and the Attestation Session in `Full_Session.json`.  The protocol and Manifest will be tailored specifically for the `attest` scenario, however the Attestation Session will have extra config items to support later scenarios.  TIP:  Open these JSON files in an editor that supports JSON formatting/syntax highlighting (we recommend VS-Code).

Looking briefly at the fields for the Manifest (`Manifest_P0.json`): 
* `"ASPS"` contains a JSON Array of supported ASP_IDs (ASP Identifiers).  In this case, it is a singleton array ["attest"].
* `"ASP_FS_MAP"` contains a JSON object of key/value pairs that maps ASP_IDs to their corresponding executable binary file system locations.  When this value is empty, the default path assigned to the binary is <ASP_BIN>/<ASP_ID>, where ASP_BIN is an environment variable pointing to the ASP executables, and <ASP_ID> is the ASP_ID mentioned in the `"ASPS"` field.  So in this case, the "attest" ASP_ID would map to an executable at path:  `<ASP_BIN>/attest`.  For this demo, <ASP_BIN> defaults to:  `<AM_REPOS_ROOT>/asp-libs/target/release/`.  The implementation for the "attest" binary is a rust source file located at:  `<AM_REPOS_ROOT>/asp-libs/executables/attest/src/main.rs`.  Its [implementation](https://github.com/ku-sldg/asp-libs/blob/maestro-summit/executables/attest/src/main.rs) is quite simple, returning only "dummy" evidence:  the string "attest".  The implementation is further simplified by leveraging the Copland-specific library function `handle_body` from the common rust-am-lib repository [here](https://github.com/ku-sldg/rust-am-lib/blob/045e9c65d81761cc09743f487f8053de996050ee/src/copland.rs#L458).  We will revisit ASP implementations later in more detail.
* `"Policy"` is related to evidence disclosure, but is left unimplemented for this demo.

Finally, looking at the fields for the Attestation Session (`Full_Session.json`):
* `"Plc_Mapping"` tells protocol participants how to map PLC_IDs (Place identifiers) to UUID strings that capture concrete AM addresses (with format:  "`<IP>:<PORT>`").  For instance, `"P0": "127.0.0.1:5000"` says that place `"P0"` maps to port 5000 on localhost (127.0.0.1).
* `"Sesion_Context": {"ASP_Types":  ` informs the evidence bundling procedure (internal to each AM) how each ASP consumes and produces new raw evidence.  In summary, the ASP_Type specification for "attest" says that "attest" should consume all input evidence (`"EvInSig": "ALL"`), and extend the evidence bundle by one value (`"EXTEND", ... "OutN", ... "1"`).  
* `"Sesion_Context": {"ASP_Comps"` indicates a "compatibility map" for ASPs, mapping attestation ASP_IDs to corresponding appraisal ASP_IDs.  These are not strictly necessary for this "attest" protocol scenario because it does not yet include the Copland appraisal primitive (`APPR`).
* `"PubKey_Mapping"` tells protocol participants how to map PLC_IDs to public key strings (used for cryptographic operations like checking signatures, encryption).

### cert protocol (local)

Next, we'll move to a slightly more complex protocol scenario, albeit still local to one machine.  The Copland syntax for the `cert` protocol is as follows:

```
*P0:  
    @P1 [ <attest P1 sys_targ> ->
          @P2 [ <appraise P2 sys_targ> ->
                <certificate P2 sys_targ> ]
        ]
```
Conceptually, this protocol involves collecting evidence at place `P1` (via `attest`), then sending that evidence to place `P2` to be appraised (via `appraise`) and finally certified (via `certificate`).  For simplicity, `appraise` and `certificate` are implemented as dummy measurements similar to `attest` that return dummy values "appraise" and "certificate", respectively.

To run this protocol, from `am-cakeml/tests/`, run:

```
./CI/Test.sh -t cert -s
```

Notice in the output that the resulting Raw Evidence is a sequence of three values (representing the base64 representations of the "attest", "appraise", and "certificate" strings):

```
"...PAYLOAD":{"RAWEV":{"RawEv":["Y2VydGlmaWNhdGU=","YXBwcmFpc2U=","YXR0ZXN0"]}...
```

### attest protocol (standalone AM server)