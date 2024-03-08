#!/bin/bash
continue_script=true

# Copiar el archivo configtx/configtx.yaml en el folder ./hyperledger-config/orderer/
CONFIGTX_PATH="./configtx/configtx.yaml"
if [ -d "./hyperledger-config/orderer" ]; then
    # Copiar el archivo configtx.yaml al directorio correcto si este existe
    cp "${CONFIGTX_PATH}" "./hyperledger-config/orderer/configtx.yaml"
else
    echo -e "\e[1;31;❌ folder ./hyperledger-config/orderer doesnt exist. \e[0m"
    return 1
fi

# Definir la ruta al bloque de génesis del canal
CHANNEL_BLOCK_PATH="./channel-artifacts/universidadeschannel.block"
CHANNEL_NAME="universidadeschannel"

# Configuración para el orderer
export ORDERER_CA="${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem"
export ORDERER_ADMIN_TLS_SIGN_CERT="${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt"
export ORDERER_ADMIN_TLS_PRIVATE_KEY="${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key"
export FABRIC_CFG_PATH="${PWD}/hyperledger-config/orderer"

# Imprimir variables de ambiente
echo "ORDERER_CA: $ORDERER_CA"
echo "ORDERER_ADMIN_TLS_SIGN_CERT: $ORDERER_ADMIN_TLS_SIGN_CERT"
echo "ORDERER_ADMIN_TLS_PRIVATE_KEY: $ORDERER_ADMIN_TLS_PRIVATE_KEY"
echo "FABRIC_CFG_PATH: $FABRIC_CFG_PATH"

# Unimos el orderer al channel
echo -e "\e[1;33mjoining orderers to channel...\e[0m"
osnadmin channel join --channelID ${CHANNEL_NAME} --config-block $CHANNEL_BLOCK_PATH  -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
if [ $? -ne 0 ]; then
    echo -e "\e[1;31m❌ Failed to join orderer to channel ${CHANNEL_NAME}.\e[0m"
    return 1  
fi
echo "---------------------------------------------"

# Listar canales para el orderer
echo -e "\e[1;33morderer channel list...\e[0m"
osnadmin channel list -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
echo "---------------------------------------------"

# Configuración para los peers
declare -A peers
peers=(
    ["peer0.madrid.universidades.com:7051"]="MadridMSP|${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp"
    ["peer0.bogota.universidades.com:9051"]="BogotaMSP|${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp"
    ["peer0.berlin.universidades.com:2051"]="BerlinMSP|${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/Admin@berlin.universidades.com/msp"
    ["peer0.iebs.universidades.com:4051"]="IebsMSP|${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt|${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp"
)

# Habilitar TLS 
export CORE_PEER_TLS_ENABLED=true
echo -e "\e[1;33mjoining peers to channel...\e[0m"

# Unir cada peer al canal
for peer_address in "${!peers[@]}"; do
    IFS='|' read -ra ADDR <<< "${peers[$peer_address]}"
    ORGANIZATION=$(echo $peer_address | cut -d '.' -f2)
    PORT=$(echo $peer_address | cut -d ':' -f2)
    export CORE_PEER_LOCALMSPID="${ADDR[0]}"
    export CORE_PEER_TLS_ROOTCERT_FILE="${ADDR[1]}"
    export CORE_PEER_MSPCONFIGPATH="${ADDR[2]}"
    export CORE_PEER_ADDRESS="localhost:$PORT"

    # Imprimir variables de ambiente
    echo "CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
    echo "CORE_PEER_TLS_ROOTCERT_FILE: $CORE_PEER_TLS_ROOTCERT_FILE"
    echo "CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"
    echo "CORE_PEER_ADDRESS: $peer_address"

    # Copiar el archivo configtx/configtx.yaml en el folder ./hyperledger-config/${org}
    if [ -d "./hyperledger-config/${ORGANIZATION}" ]; then
        # Copiar el archivo configtx.yaml al directorio correcto si este existe
        cp "${CONFIGTX_PATH}" "./hyperledger-config/${ORGANIZATION}/configtx.yaml"
    else
        echo "\e[1;31;❌ folder ./hyperledger-config/${ORGANIZATION} doesnt exist."
        return 1
    fi

    # Establecer FABRIC_CFG_PATH al directorio de la organización
    export FABRIC_CFG_PATH="${PWD}/hyperledger-config/${ORGANIZATION}"

    # Validar la existencia del archivo del certificado TLS ROOT
    if [ ! -f "$CORE_PEER_TLS_ROOTCERT_FILE" ]; then
        echo -e "\e[1;31;❌ file certificate TLS ROOT doesnt exist: $CORE_PEER_TLS_ROOTCERT_FILE \e[0m"
        continue 
    fi

    # Validar la existencia del directorio MSPCONFIGPATH
    if [ ! -d "$CORE_PEER_MSPCONFIGPATH" ]; then
        echo -e "\e[1;31;❌ folder MSPCONFIGPATH doesnt exist: $CORE_PEER_MSPCONFIGPATH \e[0m"
        continue 
    fi

    # Validar la existencia del bloque del canal
    if [ ! -f "$CHANNEL_BLOCK_PATH" ]; then
        echo -e "\e[1;31;❌ block channel file doesnt exist: $CHANNEL_BLOCK_PATH \e[0m"
        return 1 
    fi

    join_output=$(peer channel join -b "$CHANNEL_BLOCK_PATH" 2>&1)
    join_exit_code=$?
    if [ $join_exit_code -ne 0 ]; then
        # Buscar el mensaje específico del error
        if echo "$join_output" | grep -q "ledger .* already exists with state .*"; then
            echo -e "\e[1;33m⚠️ peer ${peer_address} is already joined to the channel ${CHANNEL_NAME}.\e[0m"
        else
            echo -e "\e[1;31m❌ failed to join peer $CORE_PEER_ADDRESS to channel ${CHANNEL_NAME}.\e[0m"
            echo -e "\e[1;31m❌ error: $join_output\e[0m"
            echo "---------------------------------------------"
            return 1
        fi
    else
        echo -e "\e[1;32m✅ ${peer_address} was joined to the channel $CHANNEL_NAME successfully.\e[0m"
    fi
    echo "---------------------------------------------"
done