#!/bin/bash

# Version: 0.1

# Load config file
configfile='./config.cfg'
source "$configfile"

DATE=$(date '+%F %T')

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9C\x96${NC}"
WARNING="${RED}\xF0\x9F\x9A\xA8${NC}"

MYNODES="0"
NODESUP="0"

# curl exists and runs ok
curl --version >/dev/null 2>&1
curl_ok=$?

[[ "$curl_ok" -eq 127 ]] && \
    echo "fatal: curl not installed" && exit 2

# Check jq
jq --version >/dev/null 2>&1
jq_ok=$?

[[ "$jq_ok" -eq 127 ]] && \
    echo "fatal: jq not installed" && exit 2

# Check total nodes
echo -e ""
GETTOTALNODES=$( curl -s -k https://api.runonflux.io/daemon/getzelnodecount -o node-count.json)
TOTALNODES=$(cat node-count.json | jq ."data.total")
CUMULUS=$(cat node-count.json | jq '.data."cumulus-enabled"')
NIMBUS=$(cat node-count.json | jq '.data."nimbus-enabled"')
STRATUS=$(cat node-count.json | jq '.data."stratus-enabled"')
REWARD=$(curl -s https://api.runonflux.io/daemon/getblocksubsidy | jq '.data."miner"')
EXPLORERHEIGHT=$(curl -s -k https://api.runonflux.io/daemon/getblockcount | jq ".data")


# Run checks on array of nodes in config.cfg
for NODE in "${NODES[@]}"
 do
   MYNODES=$(($MYNODES + 1))
   curl -s -k -o $NODE.json http://"$NODE":16127/daemon/getzelnodestatus
   if [ $? -eq 0 ]
       then
           VERSION=$(curl -s -k http://"$NODE":16127/daemon/getnetworkinfo | jq ."data.subversion" | tr -d '"/' | awk -F ":" '{ print $2 }')
           STATUS=$(cat $NODE.json  | jq ."status" | tr -d '"')
           DATASTATUS=$(cat $NODE.json  | jq ."data.status" | tr -d '"')
           FLUX=$(curl -s -k http://"$NODE":16127/flux/version | jq ."data" | tr -d '"')
           TIER=$(cat $NODE.json | jq ."data.tier" | tr -d '"')
           BENCHMARK=$(curl -s -k http://$NODE:16127/benchmark/getinfo | jq ."data.version" | tr -d '"')
           GETBENCHMARK=$(curl -s -k http://$NODE:16127/benchmark/getbenchmarks | jq ."data.status" | tr -d '"')
           GETBLOCK=$(curl -s -k http://"$NODE":16127/daemon/getblockcount | jq ."data")
           curl -s -k http://"$NODE":16127/apps/listrunningapps | jq '.data[] | {Names,Image,State,Status}' | tr -d '[]{}",'  > "$NODE"-zelapps.json
           curl -s -k -o $NODE-getbenchmarks.json http://"$NODE":16127/benchmark/getbenchmarks
           CORES=$(cat $NODE-getbenchmarks.json | jq ."data.cores")
           RAM=$(cat $NODE-getbenchmarks.json | jq ."data.ram")
           EPS=$(cat $NODE-getbenchmarks.json | jq ."data.eps")
           TOALSTORAGE=$(cat $NODE-getbenchmarks.json | jq ."data.totalstorage")
           DDWRITE=$(cat $NODE-getbenchmarks.json | jq ."data.ddwrite")
           if [[ $STATUS == "success" && $DATASTATUS == "CONFIRMED" ]] ;then
               NODESUP=$(($NODESUP + 1 ))
               LASTP=$(cat $NODE.json  | jq ."data.lastpaid" | tr -d '"')
               LASTPH=$(cat $NODE.json | jq ."data.last_paid_height" | tr -d '"')
               PDATE=$(date -d @"$LASTP")
               echo -e ""
               echo -e "============================================================================================================="
               if [ "$VERSION" = "$FLUXVERSION" ]; then
                   FLUXVER="${GREEN}$VERSION${NC} ${CHECK_MARK}"
               else
                   FLUXVER="${RED}$VERSION${NC} ${X_MARK}"
               fi
               if [ "$FLUX" = "$FLUXNODEVERSION" ]; then
                   FLUXOSVER="${GREEN}$FLUX${NC} ${CHECK_MARK}"
               else
                   FLUXOSVER="${RED}$FLUX${NC} ${X_MARK}"
               fi
               if [ "$BENCHMARK" = "$FLUXBENCHMARK" ]; then
                   BENCHMARKVER="${GREEN}$BENCHMARK${NC} ${CHECK_MARK}"
               else
                   BENCHMARKVER="${RED}$BENCHMARK${NC} ${X_MARK}"
               fi
               if [ "$GETBLOCK" -ge "$EXPLORERHEIGHT" ]; then
                   NODEBLOCK="${GREEN}$GETBLOCK${NC} ${CHECK_MARK}"
               else
                   NODEBLOCK="${RED}$GETBLOCK${NC} ${X_MARK} Explorer: $EXPLORERHEIGHT"
               fi
               echo -e "FluxNodes IP: ${BLUE}$NODE${NC}\t Tier: ${BLUE}$TIER${NC}\t Status: ${GREEN}$DATASTATUS${NC} ${CHECK_MARK}"
               echo -e "Version Flux: $FLUXVER\t\t FluxOS: $FLUXOSVER\t Benchmark: $BENCHMARKVER"
               echo -e "Last paid: ${YELLOW}$PDATE${NC}\t Block: ${YELLOW}$LASTPH${NC}\t Current Block: $NODEBLOCK"
               echo -e "CPU Cores: ${CYAN}$CORES${NC}\t\t Mem: ${YELLOW}$RAM${NC}\t Total Storage:${BLUE}$TOALSTORAGE${NC}"
               echo -e "EPS: ${CYAN}$EPS${NC}\t\t Disk WriteSpeed:${BLUE}$DDWRITE${NC}"
               echo -e ""

               echo -e ""
               echo -e "Apps:"
               echo -e "------"
               if [ -s  "$NODE"-zelapps.json ]; then
                   APPS=$(grep Image "$NODE"-zelapps.json | wc -l)
                   if [ $APPS -ge 1 ];then
                           grep -A 2 Names "$NODE"-zelapps.json | grep -v Names | tr -d ' / --' | grep -Ev "^$" > apps-"$NODE"-zelapps.json
                   fi
                   for APPNAME in $(cat apps-"$NODE"-zelapps.json); do
                       APPVER=$(cat $NODE-zelapps.json | grep -A 4 $APPNAME | grep "Image" | awk -F ":" '{ print $3 }' | tr -d '",')
                       APPSTATE=$(cat $NODE-zelapps.json | grep -A 4 $APPNAME | grep "State" | tr -d '", ' | awk -F ":" '{ print $2 }')
                       APPSTATUS=$(cat $NODE-zelapps.json | grep -A 4 $APPNAME | grep "Status" | tr -d '",' | awk -F ":" '{ print $2 }')
                   if [ "$APPSTATE" = "running" ]; then
                        STATES="${GREEN}$APPSTATE${NC} ${CHECK_MARK}"
                   else
                        STATES="${RED}$APPSTATE${NC} ${X_MARK}"
                   fi
                   if [ "$APPNAME" = "fluxKadenaChainWebData" ]; then
                       if [ "$APPVER" = "$KDADATAVERSION" ]; then
                           APPVERSION="${GREEN}$APPVER${NC} ${CHECK_MARK}"
                       else
                           APPVERSION="${RED}$APPVER${NC} ${X_MARK}"
                       fi
                  else
                       if [ "$APPNAME" = "zelKadenaChainWebNode" ]; then
                           if [ "$APPVER" = "$KDANODEVERSION" ]; then
                               APPVERSION="${GREEN}$APPVER${NC} ${CHECK_MARK}"
                           else
                               APPVERSION="${RED}$APPVER${NC} ${X_MARK}"
                           fi
                           # Fetch nodes block height
                           KDANODEHEIGHT=$(curl -k -s https://"$NODE":30004/chainweb/0.0/mainnet01/cut | jq ".height")
                       else
                           if [[ "$APPVER" == *"latest"* ]]; then
                               APPVERSION="${GREEN}$APPVER${NC} ${CHECK_MARK}"
                           else
                               APPVERSION="${RED}$APPVER${NC} ${X_MARK}"
                           fi
                       fi
                   fi
                   if [[ "$APPSTATUS" == *"Up"* ]]; then
                        APPSTATS="${GREEN}$APPSTATUS${NC} ${CHECK_MARK}"
                   else
                        APPSTATS="${RED}$APPSTATUS${NC} ${X_MARK}"
                   fi
                   if [[ "$APPSTATUS" == *"Up"* ]]; then
                        APPSTATS="${GREEN}$APPSTATUS${NC} ${CHECK_MARK}"
                   else
                        APPSTATS="${RED}$APPSTATUS${NC} ${X_MARK}"
                   fi
                   if [ "$APPNAME" = "zelKadenaChainWebNode" ]; then
                       echo -e "Name: ${GREEN}$APPNAME${NC}"
                       echo -e "Version: $APPVERSION\tState: $STATES\tApp status: $APPSTATS\tHeight: ${YELLOW}$KDANODEHEIGHT${NC}"
                   else
                       echo -e "Name: ${GREEN}$APPNAME${NC}"
                       echo -e "Version: $APPVERSION\tState: $STATES\tApp status: $APPSTATS\t"
                   fi
                   done
               fi
           fi
           else
               echo -e "============================================================================"
               echo -e "FluxNode IP: ${YELLOW}$NODE${NC} ${RED}failed ${X_MARK}"
               echo -e "Status: ${RED}Not confirmed${NC}"
   fi
   # Clean up
   rm -f node-count.json
   rm -f $NODE.json
   rm -f $NODE-zelapps.json
   rm -f apps-$NODE-zelapps.json
   rm -f $NODE-getbenchmarks.json
done
echo -e ""
echo -e "Summary Node status"
echo -e "============================="
if [ $NODESUP -eq $MYNODES ]; then
echo -e "Nodes Total: ${BLUE}$MYNODES${NC} Up: ${GREEN}$NODESUP${NC} ${CHECK_MARK}"
   echo -e "${GREEN}All good!${NC}"
else
   echo -e "Nodes Total: ${BLUE}$MYNODES${NC} Up: ${RED}$NODESUP${NC} ${X_MARK}"
   echo -e "All nodes ${RED}NOT${NC} confirmed"

fi
echo -e ""
echo -e "Total nodes: $TOTALNODES\tCumulus: $CUMULUS\tNimbus: $NIMBUS\tStratus: $STRATUS"
echo -e "Total Block Reward: $REWARD"
exit