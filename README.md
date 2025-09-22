# Brainstorm BIDS App: Resting State 
BIDS App that runs the **Brainstorm** MEG pipeline (import → preprocessing → sensor‑space → source‑space) in a fully automated container, with the option to execute the same pipeline as four modular sub‑steps. This pipeline is based on resting-state analysis, published https://doi.org/10.3389/fnins.2019.00284 and scipted in https://github.com/brainstorm-tools/brainstorm3/blob/master/toolbox/script/tutorial_omega.m

> **Project status**: active development. Image tags reflect Brainstorm commit and MATLAB Runtime. See **Versioning**.

---

## Table of contents

* [What is this?](#what-is-this)
* [Key features](#key-features)
* [Pipeline overview](#pipeline-overview)
* [Command‑line interface](#command-line-interface)
* [Quick start (Docker)](#quick-start-docker)
* [Quick start (Apptainer/Singularity on HPC)](#quick-start-apptainersingularity-on-hpc)
* [Inputs & outputs](#inputs--outputs)
* [Configuration](#configuration)
* [Performance & resources](#performance--resources)
* [Reproducibility & versioning](#reproducibility--versioning)
* [Testing with the OMEGA dataset](#testing-with-the-omega-dataset)
* [Troubleshooting](#troubleshooting)
* [Development](#development)
* [Contributing](#contributing)
* [Citations](#citations)
* [License](#license)

---

## What is this?

**Brainstorm BIDS App** is a containerized command‑line tool that executes Brainstorm’s MATLAB **`process_*`** APIs on BIDS‑formatted **MEG** datasets. It supports:

* End‑to‑end run (import → preproc → sensor → source)
* Modular sub‑steps to integrate into larger workflows
* BIDS Derivatives‑compliant outputs and provenance metadata

This repository packages a compiled MATLAB application against **MATLAB Runtime R2023a (v9.14)** and a pinned **Brainstorm commit** to guarantee consistent results.

---

## Key features

* **BIDS in / BIDS derivatives out**: reads BIDS MEG; writes derivatives + a Brainstorm protocol folder.
* **Four granular steps**: `import`, `preproc`, `sensor`, `source`, or `all`.
* **Deterministic builds**: image tag encodes Brainstorm commit and MCR version.
* **HPC‑friendly**: works with **Apptainer/Singularity**; respects resource flags.
* **Provenance**: JSON sidecars capture parameters, software versions, logs, and hashes.
* **Defaults aligned with Brainstorm’s Omega tutorial** (see `config/defaults.yaml`), while remaining fully overridable.

---

## Pipeline overview

The app orchestrates Brainstorm’s `tutorial_omega.m` pipeline into four modules. You may run **all** or any subset.

1. **Import & Filesystem Init**

   * Creates/loads a Brainstorm **Protocol**.
   * Indexes BIDS entities (subjects, sessions, runs, tasks).
   * Optionally selects a template anatomy (e.g., ICBM152) or uses subject MRI/FreeSurfer derivatives if present.

2. **Preprocessing**

   * Bad channel detection (auto + manual overrides).
   * Notch filtering at powerline harmonics.
   * High/low‑pass filtering.
   * SSP/ICA for blink (EOG) and cardiac (ECG) cleanup.
   * Optional epoching and artifact rejection.

3. **Sensor‑space analysis**

   * Power spectra / FFT.
   * Time‑frequency decomposition (e.g., Morlet wavelets).
   * Noise covariance estimation (e.g., empty‑room or baseline).

4. **Source‑space analysis**

   * Head model/BEM (e.g., OpenMEEG) or spherical models.
   * Inverse solution (e.g., wMNE, dSPM, sLORETA) with depth weighting.
   * Source maps/time series & summary figures.

> **Note**: Defaults are provided in `config/defaults.yaml`, derived from Brainstorm’s `tutorial_omega.m`. Everything can be overridden via CLI flags or a config file.

---

## Command‑line interface

**BIDS‑Apps style**:

```
brainstorm-bids-app \
  <bids_root> <derivatives_root> <analysis_level> \
  [--participant_label <sub-01> <sub-02> ...] \
  [--session_label <ses-01> <ses-02> ...] \
  [--task <taskname>] [--run <01 02 ...>] \
  [--step all|import|preproc|sensor|source] \
  [--config /path/to/config.(yaml|json)] \
  [--n_cpus 8] [--mem_mb 16000] [--omp_nthreads 8] \
  [--work-dir /work] [--clean-workdir] \
  [--anatomy template|subject] [--template ICBM152] \
  [--headmodel openmeeg|bem|sphere] \
  [--inverse wmne|dspm|sloreta]
```

Where:

* `<analysis_level>` is `participant` or `group`.
* `--step` chooses a single module or `all` for the end‑to‑end pipeline.
* Use `--config` to pass a full parameter set. CLI flags override file settings.

**Short help**: `brainstorm-bids-app -h`

---

## Quick start (Docker)

1. **Pull the image** (replace the tag with a release from DockerHub):

   ```bash
   docker pull diellorbasha/brainstorm-rs-bids-app:<tag>
   ```

2. **Run end‑to‑end** on a local BIDS dataset:

   ```bash
   docker run --rm -it \
     -v $PWD/dsBIDS:/bids:ro \
     -v $PWD/derivatives:/out \
     -v $PWD/work:/work \
     -e MCR_CACHE_ROOT=/work/mcr_cache \
     diellorbasha/brainstorm-rs-bids-app:<tag> \
       /bids /out participant \
       --step all \
       --n_cpus 8 --omp_nthreads 8 --mem_mb 16000 \
       --work-dir /work
   ```

3. **Run a single module** (e.g., preprocessing only):

   ```bash
   docker run --rm -it \
     -v $PWD/dsBIDS:/bids:ro \
     -v $PWD/derivatives:/out \
     -v $PWD/work:/work \
     -e MCR_CACHE_ROOT=/work/mcr_cache \
     diellorbasha/brainstorm-rs-bids-app:<tag> \
       /bids /out participant --step preproc
   ```

> Tip: To avoid root‑owned outputs on Linux, add `--user $(id -u):$(id -g)`.

---

## Quick start (Apptainer/Singularity on HPC)

Use the Docker image directly with Apptainer:

```bash
apptainer run --cleanenv \
  -B $PWD/dsBIDS:/bids:ro \
  -B $PWD/derivatives:/out \
  -B $PWD/work:/work \
  docker://diellorbasha/brainstorm-rs-bids-app:<tag> \
    /bids /out participant --step all \
    --n_cpus $SLURM_CPUS_PER_TASK --mem_mb 16000 --work-dir /work
```

**SLURM example** (`--time`, `--mem`, `--cpus-per-task` as appropriate):

```bash
#!/bin/bash
#SBATCH --job-name=bst-bids
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G

module load apptainer
export TMPDIR=$PWD/tmp
mkdir -p "$TMPDIR" work derivatives

apptainer run --cleanenv \
  -B $PWD/dsBIDS:/bids:ro \
  -B $PWD/derivatives:/out \
  -B $PWD/work:/work \
  docker://diellorbasha/brainstorm-rs-bids-app:<tag> \
    /bids /out participant --step all \
    --n_cpus ${SLURM_CPUS_PER_TASK} --mem_mb 16000 --work-dir /work
```

---

## Inputs & outputs

### Inputs

* **BIDS MEG dataset** at `<bids_root>` (read‑only mount recommended)
* Optional **derivatives** (e.g., FreeSurfer) discoverable under BIDS structure
* Optional **config file** (YAML/JSON) to customize parameters

### Outputs

Written under `<derivatives_root>`:

* `derivatives/brainstorm/` (BIDS‑Derivatives):

  * Processed sensor‑space derivatives (e.g., spectra, TFR, covariance)
  * Source‑space derivatives (head models, inverse, source maps)
  * Sidecar JSON with parameters & software versions
* `brainstorm_protocol/`:

  * Brainstorm **Protocol** folder mirroring results for GUI inspection
* `logs/`:

  * One log per subject/session/run, plus global run log

> Use Brainstorm GUI to browse the Protocol folder after the run if desired.

---

## Configuration

All parameters can be provided via `--config` (YAML/JSON). CLI flags always override the file. A minimal example:

```yaml
# config/example.yaml
pipeline:
  step: all                 # all|import|preproc|sensor|source
  workDir: /work
  anatomy: template         # template|subject
  template: ICBM152

import:
  protocolName: BST_BIDS
  overwrite: false

preproc:
  highpassHz: 0.3
  lowpassHz: 150
  notchHz: [60, 120, 180]
  badChannel: { method: auto, manual: [] }
  blinkCleanup: { method: SSP }
  cardiacCleanup: { method: SSP }
  epoching: { doEpoch: false }

sensor:
  psd: { doPSD: true }
  tfr: { method: morlet, freqs: [2, 100] }
  noiseCov: { strategy: emptyroom }

source:
  headmodel: openmeeg        # openmeeg|bem|sphere
  inverse: wmne              # wmne|dspm|sloreta
  depthWeighting: 0.8
```

> The repository provides `config/defaults.yaml` derived from Brainstorm’s **Omega tutorial**; adapt as needed.

---

## Performance & resources

* **MATLAB Runtime** caches to `MCR_CACHE_ROOT` (set to a writable fast disk, e.g., `/work/mcr_cache`).
* Use `--n_cpus`, `--omp_nthreads`, and `--mem_mb` to tune performance.
* On HPC, prefer **local scratch** for `--work-dir`.
* Typical minimal resources to process a single subject: `--n_cpus 4`, `--mem_mb 8000` (adjust for data size and steps enabled).

---

## Reproducibility & versioning

* **Brainstorm commit** pinned in the image: **`238abb0`**.
* **MATLAB Runtime**: **R2023a (v9.14)**.
* **Docker tags** follow: `vMAJOR.MINOR.PATCH-<commit>-mcr914` (e.g., `v0.1.0-238abb0-mcr914`).
* Each run writes a **provenance JSON** with:

  * Image tag & digest
  * Brainstorm commit & MATLAB Runtime version
  * CLI & config parameters
  * Checksums of key inputs/outputs

---

## Testing with the OMEGA dataset

Use the public **OMEGA BIDS‑MEG** dataset (`ds000247`) for smoke tests and examples.

Example (Docker):

```bash
# assuming ds000247 cloned to ./ds000247
docker run --rm -it \
  -v $PWD/ds000247:/bids:ro \
  -v $PWD/derivatives:/out \
  -v $PWD/work:/work \
  -e MCR_CACHE_ROOT=/work/mcr_cache \
  diellorbasha/brainstorm-rs-bids-app:<tag> \
    /bids /out participant --step all --work-dir /work
```

---

## Troubleshooting

* **Permission denied / read‑only**: ensure `/out` and `/work` are writable; consider `--user $(id -u):$(id -g)`.
* **MCR cache errors**: set `MCR_CACHE_ROOT` to a writable directory (e.g., `/work/mcr_cache`).
* **No subjects found**: check BIDS structure and `--participant_label`/`--session_label` filters.
* **Missing anatomy**: set `--anatomy template` (default) or provide subject MRIs/FreeSurfer derivatives.
* **OpenMEEG/BEM issues**: switch head model via `--headmodel sphere` to test; verify geometry availability for BEM.
* **Out‑of‑memory**: reduce concurrency, free disk, or increase `--mem_mb`; use local scratch for `--work-dir`.

---

## Development

### Repository layout

```
/cli/                   # Python or bash wrapper that parses BIDS & launches compiled MATLAB runner
/matlab/                # Orchestrator & process_* calls (pre‑compile sources)
/config/                # defaults.yaml + example configs
/docker/                # Dockerfile, entrypoint, runtime setup
/tests/                 # smoke tests, OMEGA scenarios
/docs/                  # extra documentation
```

### Build the image

```bash
# Build with pinned Brainstorm commit and MCR
docker build -t brainstorm-bids-app:dev -f docker/Dockerfile .
```

### Local run (developer mode)

You can mount the MATLAB sources (uncompiled) and run in **MATLAB** or **MATLAB Runtime** depending on your setup. See `docker/dev.Dockerfile` and `docs/dev.md`.

### Style & CI

* Lint CLI scripts; enforce BIDS entity parsing rules.
* CI runs smoke tests on ds000247 subsets.

---

## Contributing

Contributions are welcome! Please:

1. Open an issue describing the feature/bug.
2. Propose an interface (CLI flags / config schema).
3. Submit a PR with tests and documentation updates.

---

## Citations

If you use this app in your research, please cite:

* **Brainstorm**: Tadel F, Baillet S, Mosher JC, Pantazis D, Leahy RM. *Brainstorm: A User‑Friendly Application for MEG/EEG Analysis*. Computational Intelligence and Neuroscience, 2011.
* **BIDS**: Gorgolewski KJ et al. *The brain imaging data structure, a format for organizing and describing outputs of neuroimaging experiments.* Scientific Data, 2016.
* **This BIDS App**: *Brainstorm BIDS App* (this repository & corresponding Docker image tag used).

---

## License

* **Brainstorm code** is distributed under the terms of its upstream license.
* The **container build scripts and CLI** in this repository are released under **GPL‑3.0** unless stated otherwise.
* See `LICENSE` for details.

---

### Maintainers & image

* DockerHub: `diellorbasha/brainstorm-rs-bids-app:<tag>`
* Brainstorm commit pinned: `238abb0`
* MATLAB Runtime: **R2023a (9.14)**

---

### Appendix: Example CLI recipes

* **Preproc only, two subjects**

  ```bash
  brainstorm-bids-app /bids /out participant \
    --participant_label sub-0001 sub-0002 \
    --step preproc --n_cpus 8 --work-dir /work
  ```
* **Group‑level summary after participant runs**

  ```bash
  brainstorm-bids-app /bids /out group --step sensor
  ```
* **Switch head model & inverse**

  ```bash
  brainstorm-bids-app /bids /out participant \
    --step source --headmodel sphere --inverse dspm
  ```


## References:
https://doi.org/10.3389/fnins.2019.00284
https://neuroimage.usc.edu/brainstorm/Tutorials/RestingOmega
