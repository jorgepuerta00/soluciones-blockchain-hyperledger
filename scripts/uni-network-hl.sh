#!/bin/bash
clear
echo -e "\e[1;35m🔥 Setting up hyperledger network for student managment 🔥\e[0m"

# Cleaning docker containers and images
docker stop $(docker ps -a -q)
echo -e "\e[1;32m✅ Stopped containers\e[0m"

docker rm $(docker ps -a -q)
echo -e "\e[1;32m✅ Deleted containers\e[0m"

docker system prune -af
docker volume prune --filter all=1
echo -e "\e[1;32m✅ Deleted images and volumnes\e[0m"

docker network prune -f
echo -e "\e[1;32m✅ Deleted networks\e[0m"

docker-compose -f docker/docker-compose-universidades.yaml -f docker/docker-compose-ca.yaml down --remove-orphans
echo -e "\e[1;32m✅ Removed docker compose orphans\e[0m"

# Removing directories
sudo chown -R $USER:$USER organizations
rm -rf organizations/peerOrganizations
rm -rf organizations/ordererOrganizations
rm -rf organizations/fabric-ca/ordererOrg/
rm -rf organizations/fabric-ca/madrid/
rm -rf organizations/fabric-ca/bogota/
rm -rf organizations/fabric-ca/berlin/
rm -rf organizations/fabric-ca/iebs/
rm -rf channel-artifacts/
echo -e "\e[1;32m✅ Removed ca folders\e[0m"

# Creating channel-artifacts directory
mkdir channel-artifacts
echo -e "\e[1;32m✅ Created channel-artifacts directory\e[0m"

# Setting environment variables
export PATH=${PWD}/fabric-sample/bin:${PWD}:$PATH
echo -e "\e[1;32m✅ Setup environment variables\e[0m"
echo "---------------------------------------------"

# Generating CA containers for orderes and orgs
echo -e "\e[1;35m➡️ Generating CA containers for orderes and organizations\e[0m"
docker-compose -f docker/docker-compose-ca.yaml up -d
echo -e "\e[1;32m✅ Setup CA containers\e[0m"
echo "---------------------------------------------"

# Registring and enrolling peers and users
echo -e "\e[1;35m➡️ Registring and enrolling peers and users\e[0m"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createMadrid
echo "---------------------------------------------"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createBogota
echo "---------------------------------------------"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createBerlin
echo "---------------------------------------------"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createIebs
echo -e "\e[1;32m✅ Peers enrolled successfully\e[0m"
echo "---------------------------------------------"

# Registring and enrolling orderer
echo -e "\e[1;35m➡️ Registring and enrolling orderer\e[0m"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createOrderer
echo -e "\e[1;32m✅ Orderer enrolled successfully\e[0m"
echo "---------------------------------------------"

# Generation of the genesis block
echo -e "\e[1;35m➡️ Generating the genesis block\e[0m"
export FABRIC_CFG_PATH=${PWD}/configtx
configtxgen -profile UniversidadesGenesis -outputBlock ./channel-artifacts/universidadeschannel.block -channelID universidadeschannel
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed to generated genesis block\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Genesis block generated successfully\e[0m"
echo "---------------------------------------------"

# Starting the network
echo -e "\e[1;35m➡️ Starting hyperledger network orderes, peers and couchdb\e[0m"
docker-compose -f docker/docker-compose-universidades.yaml up -d
echo -e "\e[1;32m✅ Setup hyperledger components successfully\e[0m"
echo "---------------------------------------------"

# Joining the orders and peers to the channel
echo -e "\e[1;35m➡️ Joining orders & peers to the channel\e[0m"
sleep 10
. ./scripts/join_channel.sh

# Listing the channels
. ./scripts/channel_list.sh
echo -e "\e[1;32m✅ Orders and peers joined successfully\e[0m"
echo "---------------------------------------------"

# Installing and instantiating the chaincode
echo -e "\e[1;35m➡️ Installing, packing and instantiating the chaincode\e[0m"

# Check the peer version
export PATH=${PWD}/fabric-sample/bin:${PWD}:$PATH
echo -e "\e[1;33mPeer version\e[0m"
peer version
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed to get peer version\e[0m"
    return 1  
fi

# Compile chaincode
echo -e "\e[1;31;40m🚨 IMPORTANT: Remember compile chaincode before packing.\e[0m"
#export CHAINCODE_DIR=${PWD}/chaincode-go/chaincode
#GO111MODULE=on go build -mod=vendor -o "${CHAINCODE_DIR}/smartcontract" "${CHAINCODE_DIR}/smartcontract.go"
#echo -e "\e[1;32mDone \e[0m"

# Package the chaincode
export FABRIC_CFG_PATH=${PWD}/configtx
peer lifecycle chaincode package registroAlumnos.tar.gz --path ${CHAINCODE_DIR} --label registroAlumnos_1.0
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed packaging chaincode\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Chaincode was packaged successfully\e[0m"

# Install the chaincode
sleep 2
. ./scripts/install_chaincode.sh
echo -e "\e[1;32m✅ Chaincode was installed successfully\e[0m"

# Query the installed chaincodes
query_result=$(peer lifecycle chaincode queryinstalled)
package_id=$(echo "$query_result" | grep "Package ID:" | sed 's/.*: \([^,]*\),.*/\1/')
export CHAINCODE_PACKAGE_ID="$package_id"
echo -e "\e[1;32m✅ Chaincode package Id ${CHAINCODE_PACKAGE_ID}\e[0m"

# Approve the chaincode for each organization
sleep 2
. ./scripts/approve-chaincode.sh $CHAINCODE_PACKAGE_ID
echo -e "\e[1;32m✅ Chaincode approved successfully\e[0m"

# Check the commit readiness of the chaincode
peer lifecycle chaincode checkcommitreadiness \
    --channelID universidadeschannel \
    --name registroAlumnos \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem \
    --output json
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed checkcommitreadiness chaincode\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Chaincode checkcommitreadiness successfully\e[0m"

# Commit the chaincode
peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.universidades.com \
    --channelID universidadeschannel \
    --name registroAlumnos \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem \
    --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt \
    --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt \
    --peerAddresses localhost:2051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt \
    --peerAddresses localhost:4051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed commiting chaincode\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Chaincode commited successfully\e[0m"

# Query the committed chaincode
echo -e "\e[1;33mQuerying the committed chaincode... \e[0m"
peer lifecycle chaincode querycommitted \
    --channelID universidadeschannel \
    --name registroAlumnos \
    --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed querycommitted chaincode\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Chaincode querycommitted successfully\e[0m"

# Invoking the chaincode to initialize the ledger
export CORE_PEER_LOCALMSPID="MadridMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

echo -e "\e[1;35m➡️ Invoking the chaincode to initialize the ledger\e[0m"
peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.universidades.com \
    --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem \
    -C universidadeschannel \
    -n registroAlumnos \
    --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt \
    --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt \
    --peerAddresses localhost:2051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt \
    --peerAddresses localhost:4051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt \
    -c '{"function":"InitLedger","Args":[]}'
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed Invoking InitLedger chaincode\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Chaincode invoked InitLedger successfully\e[0m"

# Hitting the couchdb to check the ledger
sleep 5
echo "---------------------------------------------"
curl -X GET http://admin:adminpw@localhost:5984/universidadeschannel_ | jq .
echo "---------------------------------------------"

# Invoking the chaincode to get all students
echo -e "\e[1;33mInvoking the chaincode to get all students... \e[0m"
peer chaincode query -C universidadeschannel -n registroAlumnos -c '{"Args":["GetAllStudents"]}' | jq .
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed Invoking GetAllStudents chaincode\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Chaincode invoked GetAllStudents successfully\e[0m"

# Invoking the chaincode to register a student
echo -e "\e[1;33mInvoking the chaincode to register a student... \e[0m"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem -C universidadeschannel -n registroAlumnos --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt --peerAddresses localhost:2051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt --peerAddresses localhost:4051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt -c '{"Args":["CreateStudent","student7","John","Doe","USA","madrid.universidades.com"]}'
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed Invoking CreateStudent chaincode\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Chaincode invoked CreateStudent successfully\e[0m"

# Invoking the chaincode to get all students
echo -e "\e[1;33mInvoking the chaincode to get all students... \e[0m"
sleep 5
peer chaincode query -C universidadeschannel -n registroAlumnos -c '{"Args":["GetAllStudents"]}' | jq .
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m❌ failed Invoking GetAllStudents chaincode\e[0m"
    return 1  
fi
echo -e "\e[1;32m✅ Chaincode invoked GetAllStudents successfully\e[0m"

# Hitting the couchdb to check the ledger
echo "---------------------------------------------"
curl -X GET http://admin:adminpw@localhost:5984/universidadeschannel_ | jq .
echo "---------------------------------------------"

