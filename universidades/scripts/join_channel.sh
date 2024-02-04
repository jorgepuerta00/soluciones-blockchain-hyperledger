#!/bin/bash

# Definir la ruta al bloque de génesis del canal
CHANNEL_BLOCK_PATH="./channel-artifacts/universidadeschannel.block"
CHANNEL_NAME="universidadeschannel"

# Configuración para el orderer
export ORDERER_CA="${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem"
export ORDERER_ADMIN_TLS_SIGN_CERT="${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt"
export ORDERER_ADMIN_TLS_PRIVATE_KEY="${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key"

# Listar canales para el orderer
echo "Listando canales para el orderer..."
osnadmin channel list -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
echo "---------------------------------------------"

# Configuración para los peers
declare -A peers
peers=(
    ["peer0.madrid.universidades.com:7051"]="MadridMSP|${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp"
    ["peer0.bogota.universidades.com:9051"]="BogotaMSP|${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp"
    ["peer0.berlin.universidades.com:2051"]="BerlinMSP|${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/Admin@berlin.universidades.com/msp"
)

# Habilitar TLS 
export CORE_PEER_TLS_ENABLED=true

# Unir cada peer al canal
for peer_address in "${!peers[@]}"; do
    IFS='|' read -ra ADDR <<< "${peers[$peer_address]}"
    export CORE_PEER_LOCALMSPID="${ADDR[0]}"
    export CORE_PEER_TLS_ROOTCERT_FILE="${ADDR[1]}"
    export CORE_PEER_MSPCONFIGPATH="${ADDR[2]}"
    export CORE_PEER_ADDRESS="$peer_address"

    echo "Uniendo el peer $CORE_PEER_ADDRESS al canal ${CHANNEL_NAME}..."
    peer channel join -b $CHANNEL_BLOCK_PATH
    echo "Peer unido al canal."
    echo "---------------------------------------------"
done
