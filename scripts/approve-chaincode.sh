#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 1 ]; then
    echo -e "\e[1;31;40m❌ Usage: $0 <CHAINCODE_PACKAGE_ID>\e[0m"
    return 1
fi

# Assign command-line argument to a variable
CHAINCODE_PACKAGE_ID="$1"

# Define an array of peer configurations
declare -A peers
peers=(
    ["peer0.madrid.universidades.com:7051"]="MadridMSP|${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp|${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt"
    ["peer0.bogota.universidades.com:9051"]="BogotaMSP|${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp|${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt"
    ["peer0.berlin.universidades.com:2051"]="BerlinMSP|${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/Admin@berlin.universidades.com/msp|${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt"
    ["peer0.iebs.universidades.com:4051"]="IebsMSP|${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp|${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt"
)

# Common variables
export CORE_PEER_TLS_ENABLED=true
ORDERER_ADDRESS="localhost:7050"
ORDERER_TLS_HOSTNAME_OVERRIDE="orderer.universidades.com"
CHANNEL_ID="universidadeschannel"
CHAINCODE_NAME="registroAlumnos"
CHAINCODE_VERSION="1.0"
SEQUENCE="1"
CA_FILE="${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem"

# Loop through the array and set environment variables for each peer
for peer_address in "${!peers[@]}"; do
    IFS='|' read -ra ADDR <<< "${peers[$peer_address]}"
    PORT=$(echo $peer_address | cut -d ':' -f2)
    export CORE_PEER_LOCALMSPID="${ADDR[0]}"
    export CORE_PEER_MSPCONFIGPATH="${ADDR[1]}"
    export CORE_PEER_TLS_ROOTCERT_FILE="${ADDR[2]}"
    export CORE_PEER_ADDRESS="localhost:$PORT"

    echo -e "\e[1;33mApproving chaincode for organization on peer: ${peer_address}\e[0m"
    peer lifecycle chaincode approveformyorg \
        -o $ORDERER_ADDRESS \
        --ordererTLSHostnameOverride $ORDERER_TLS_HOSTNAME_OVERRIDE \
        --channelID $CHANNEL_ID \
        --name $CHAINCODE_NAME \
        --version $CHAINCODE_VERSION \
        --package-id $CHAINCODE_PACKAGE_ID \
        --sequence $SEQUENCE \
        --tls \
        --cafile $CA_FILE

    if [ $? -ne 0 ]; then
        echo -e "\e[1;31;40m❌ failed when approveformyorg on peer: ${peer_address}.\e[0m"
        echo "---------------------------------------------"
        return 1  
    fi
    echo "---------------------------------------------"
done
