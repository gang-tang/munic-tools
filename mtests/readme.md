# mtest_perf

## 🚀 Overview: Automated RDMA Perftest Execution

The **`mtest_perf`** project provides a robust Bash wrapper script designed to automate the execution of **any RDMA perftest utility** (e.g., `ib_write_bw`, `ib_write_lat`, `ib_read_bw`, etc.) across multiple hosts and RDMA network interfaces (NICs). Its primary goal is to set up a controlled, multi-host environment for measuring various RDMA performance metrics at scale.

### Key Features

The main script, **`mtest_perf`** (originally named `mtest_write_bw`), handles:

- Configuration loading
- Command-line overrides
- Multi-host coordination via **`mpirun`** (currently validated with Open MPI 5.0.6; compatibility with earlier versions such as 4.x is not guaranteed)

A secondary script, **`mtest_perf_local`** (originally named `write_bw_test`), runs on each host and performs:

* **Process Coordination**
  Launches multiple perftest server and client instances in the background, based on the command specified in the config.

* **NUMA & CPU Pinning**
  Uses **`numactl`** and **`taskset`** to bind each process to the appropriate CPU core and NUMA node corresponding to the InfiniBand device.

* **Automatic Pairing Logic**
  Establishes client–server connections based on the ordering of `CLIENTS` and `SERVERS` from the configuration file.

* **Continuous Monitoring**
  If configured with an infinite run option (like `--run_infinitely` for `ib_write_bw`), the script streams client output and bandwidth results via `tail -f`.

---

## 🛠️ Setup and Requirements

### Dependencies

Ensure the following utilities are installed on all participating hosts:

- **InfiniBand Stack** (RDMA drivers & libraries)
- **Desired Perftest Utility** (e.g., `ib_write_bw`, `ib_read_lat`, etc.)
- **`mpirun`** (MPI implementation for multi-node execution, only tested with ompi 5.0.6)
- **`numactl`** (for CPU and memory binding)

---

## ⚙️ Configuration

The script requires a **configuration file** (e.g., `mtest_perf.env`) that defines all test parameters.

### Example: `mtest_perf.env`

This example uses the `ib_write_bw` utility. Simply change `PERFTEST_CMD` to use other utilities like `ib_write_lat` or `ib_read_bw`.

```bash
PERFTEST_CMD='ib_write_bw --run_infinitely --report_gbits'
# PERFTEST_CMD='ib_write_lat' # Example for a latency test

CLIENTS='test1:mlx5_0 test1:mlx5_1 test2:mlx5_0'     # Multiple entries allowed, space-separated
SERVERS='test2:mlx5_1 test2:mlx5_1 test2:mlx5_1'     # Must match CLIENTS count
BASE_PORT=20000
QP_NUM=2
MESSAGE_SIZE=65536
TC_CLASS=0

# Set the LD_LIBRARY_PATH environment value used in mpirun ranks.
# This is necessary if custom or non-standard RDMA libraries are used
# and the perftest executable needs to find them at runtime.
# e.g:
# CFG_LD_LIBRARY_PATH=/path/to/rdma-core/lib
```

The script automatically appends the essential perftest options (`-q`, `-p`, `-s`, `-d`, `--tclass`, and `host` for the client) based on the configuration. Any other specific perftest options should be included directly in the PERFTEST_CMD variable.

With the configuration above, the script establishes three distinct concurrent tests, using BASE_PORT (e.g., 20000) and the next two consecutive ports (20001, 20002) for communication.

| Pair Index | Client (Source)   | Server (Destination) | Execution Summary                                      |
|------------|-------------------|----------------------|--------------------------------------------------------|
| 0          | test1:mlx5_0      | test2:mlx5_1         | Cross-Host Test: Client on test1 connects to Server on test2 |
| 1          | test1:mlx5_1      | test2:mlx5_1         | Cross-Host Test: Client on test1 connects to Server on test2 |
| 2          | test2:mlx5_0      | test2:mlx5_1         | Loopback Test: Both Client and Server are on test2     |

On host `test2`, the script detects its role as a server for all three pairs. It launches three separate server processes, for example:

- **Server 0**: Binds to device `mlx5_1` and port `20000`
- **Server 1**: Binds to device `mlx5_1` and port `20001`  
- **Server 2**: Binds to device `mlx5_1` and port `20002`

All three server processes are pinned to separate, optimized CPU cores on the NUMA node associated with `mlx5_1`.

## Parameter Description

| Variable                 | Description                                                                 | Notes                                                                 |
|--------------------------|-----------------------------------------------------------------------------|-----------------------------------------------------------------------|
| `PERFTEST_CMD`           | The base perftest command and its fixed options (e.g., `ib_write_bw --run_infinitely`). | This is the command that will be executed.                           |
| `CFG_LD_LIBRARY_PATH`    | Value to set the `LD_LIBRARY_PATH` for remote MPI ranks.                    | Used to help perftest binaries find custom RDMA/IB libraries at runtime. |
| `CLIENTS`                | List of client devices                                                      | Format: `<hostname>:<nic_device>`; order defines pairing with `SERVERS`. |
| `SERVERS`                | List of server devices                                                      | Format: `<hostname>:<nic_device>`.                                   |
| `BASE_PORT`              | Starting TCP port                                                           | Ports auto-increment for each client–server pair.                    |
| `QP_NUM`                 | Number of Queue Pairs                                                       | Maps to perftest `-q` option.                                        |
| `MESSAGE_SIZE`           | Message size in bytes                                                       | Maps to perftest `-s` option.                                        |
| `TC_CLASS`               | Traffic Class                                                               | Maps to perftest `--tclass` option.                                  |

---

## 💻 Usage

### Running the Script

#### Deployment and Pre-requisites

**🌐 Multi-Host Deployment**

- Clone this project to all hosts participating in the test (defined in `CLIENTS` and `SERVERS`).
- It is critical that the repository is cloned to the **identical path** on every host for the `mpirun` command to find the necessary test scripts.

**🔑 Host Access (MPI Requirement)**

- For multi-host execution, the `mpirun` command relies on the ability to launch processes remotely.
- Ensure that all involved hosts can SSH into one another directly **without any interactive prompts** (i.e., password prompts, key prompts).
- This typically requires setting up passwordless SSH using SSH keys.

**⚙️ Configuration File**

- You must specify the configuration file using the `-c <file>` command-line parameter.
- If the `-c` parameter is not used, the script defaults to searching for a file named `./mtest_perf.env.local` in the script's execution directory.


### Basic Syntax

```bash
cd munic-tools/mtests/
./mtest_perf -c <config_file>
```

### Command-Line Overrides

You may override configuration values after the configuration file is sourced.

| Option        | Description                               | Overrides       |
|---------------|-------------------------------------------|-----------------|
| `-q <count>`  | Override number of QPs                    | `QP_NUM`        |
| `-m <size>`   | Override message size in bytes            | `MESSAGE_SIZE`  |
| `-t <class>`  | Override Traffic Class                    | `TC_CLASS`      |


### Basic Syntax

```bash
./mtest_perf -c mtest_perf.env -q 4 -m 1048576 -t 64
```

### Stopping the Test

The perftest processes may run infinitely (depending on the `PERFTEST_CMD` options).

To stop the testing:
- Press **Ctrl+C**, or
- Send **SIGTERM** to the `mtest_perf` process

The script includes a cleanup trap that ensures all related perftest client and server processes are terminated cleanly.