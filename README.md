# FNCQAD - Flux Node Check Quick And Dirty

## Overview
Check node status and version. This gives a quick overview of the current status for you nodes. Main use case is to quick see that all nodes are confirmed, synced and on the correct software versions. 

#### Basic features
!!! This do not replace watchdog in any way. !!!
Recommend using the watchdog.
Check running version against local config file. 
If updates are released wathdog will update automatically, this script just givs a quick overview of your nodes status to make sure everthing is running fine.


#### Functions
* Tier
* Node status
* Block Height (compare with explorer)
* Last Paid
* Check versions
  * Flux Deamon
  * FluxOS 
  * Flux Benchmark
  * KDA Data Node (Now a global app)
  * KDA Web Node (Now a global app)
* Node Hardware
  * CPU Cores
  * Memory
  * Total Storage
  * CPU EPS
  * Disk writespeed
* Apps
  * List running apps 
  * State
  * App status
  * Kadena Web Node block hight (compare with explorer, now a global app)


## Changes

* 0.1 First public release

## Requirement 

For Debian/Ubuntu:

```bash
sudo apt install curl
sudo apt install jq
```

#### 1) Downloading

Clone the repository

```bash
git clone https://github.com/glen487/FNCQAD
cd FNCQAD
```

#### 2) Configure
Edit the config.cfg.
When new versions are released change the value and run the check. 
Check announcement channel or watchdog activity.
Add your nodes IP address to the NODES variable. 

* FLUXVERSION="6.0.0"
* FLUXNODEVERSION="3.10.0"
* KDADATAVERSION="v1.1.0"
* KDANODEVERSION="2.13.0"
* FLUXBENCHMARK="3.1.0"
* NODES=( 192.168.1.1 192.168.2.2 ) # Sample make sure there is a space between IP addresses


#### Sample config.cfg

```bash
FLUXVERSION="6.0.0"
FLUXNODEVERSION="3.10.0"
KDADATAVERSION="v1.1.0"
KDANODEVERSION="2.13.0"
FLUXBENCHMARK="3.1.0"
NODES=( 192.168.1.1 192.168.2.2 )
```

#### 3) Run the script

```bash
chmod +x fcqad.bas
./fcqad.bash
```

#### 4) Sample output

![Flux Node Status](https://github.com/glen487/FNCQAD/blob/main/nodes.PNG)

Feel free to donate. But you dont need to! Just wanted to share. :)
```
FLUX: t1SNmBDj4wqpf4LqQaymaL6LGJcznSGWd2L  
```

License
-------
N/A
