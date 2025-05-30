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

## Running some example Copland protocols

With the tools installed, we can run some example Copland protocols with the help of MAESTRO and observe their output.  

We will assume for the rest of this tutorial that your `AM_REPOS_ROOT` environment variable is set to a path we'll refer to as `<path-to-am_repos_root>`, and the MAESTRO repositories are configured as sub-directories -- `(am-cakeml/, asp-libs/, rust-am-clients/)` -- per the earlier installation.

### attest, cert (dummy) protocols

First, navigate to 