#!/bin/bash

# Define an array of peer configurations
declare -A peers
peers=(
    ["peer0.madrid.universidades.com:7051"]="MadridMSP|${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp"
    ["peer0.bogota.universidades.com:9051"]="BogotaMSP|${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp"
    ["peer0.berlin.universidades.com:2051"]="BerlinMSP|${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/Admin@berlin.universidades.com/msp"
    ["peer0.iebs.universidades.com:4051"]="IebsMSP|${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp"
)

# Loop through the array and set environment variables for each peer
for peer_address in "${!peers[@]}"; do
    IFS='|' read -ra ADDR <<< "${peers[$peer_address]}"
    PORT=$(echo $peer_address | cut -d ':' -f2)
    export CORE_PEER_LOCALMSPID="${ADDR[0]}"
    export CORE_PEER_TLS_ROOTCERT_FILE="${ADDR[1]}"
    export CORE_PEER_MSPCONFIGPATH="${ADDR[2]}"
    export CORE_PEER_ADDRESS="localhost:$PORT"

    echo -e "\e[1;33mlisting channels for peer: $CORE_PEER_ADDRESS\e[0m"
    peer channel list
    if [ $? -ne 0 ]; then
        echo -e "\e[1;31m❌ failed to list channels for peer: ${peer_address}.\e[0m"
        echo "---------------------------------------------"
        return 1  
    fi
    echo "---------------------------------------------"
done
