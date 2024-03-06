#!/bin/bash
clear

# Cleaning docker containers and images
echo -e "\e[1;31;40m Stoping containers... \e[0m"
docker stop $(docker ps -a -q)
echo -e "\e[1;32m Done \e[0m"

echo -e "\e[1;31;40m Deleting containers... \e[0m"
docker rm $(docker ps -a -q)
echo -e "\e[1;32m Done \e[0m"

echo -e "\e[1;31;40m Deleting images and volumnes... \e[0m"
docker system prune -af
docker volume prune --filter all=1
echo -e "\e[1;32m Done \e[0m"

echo -e "\e[1;31;40m Deleting networks... \e[0m"
docker network prune -f
echo -e "\e[1;32m Done \e[0m"

echo -e "\e[1;31;40m Removing docker compose services... \e[0m"
docker-compose -f docker/docker-compose-universidades.yaml -f docker/docker-compose-ca.yaml down --remove-orphans
echo -e "\e[1;32m Done \e[0m"

# Removing directories
echo -e "\e[1;31;40m Removing directories... \e[0m"
sudo rm -rf organizations/peerOrganizations
sudo rm -rf organizations/ordererOrganizations
sudo rm -rf organizations/fabric-ca/ordererOrg/
sudo rm -rf organizations/fabric-ca/madrid.universidades.com/
sudo rm -rf organizations/fabric-ca/bogota.universidades.com/
sudo rm -rf organizations/fabric-ca/berlin.universidades.com/
sudo rm -rf organizations/fabric-ca/iebs.universidades.com/
sudo rm -rf channel-artifacts/
echo -e "\e[1;32m Done \e[0m"

# Creating channel-artifacts directory
echo -e "\e[1;31;40m Creating directories... \e[0m"
mkdir channel-artifacts
echo -e "\e[1;32m Done \e[0m"

# Setting environment variables
echo -e "\e[1;31;40m Setting environment variables... \e[0m"
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../config
echo -e "\e[1;32m Done \e[0m"

# Generating CA containers for orderes and orgs
echo -e "\e[1;31;40m Generating CA containers for orderes and orgs... \e[0m"
docker-compose -f docker/docker-compose-ca.yaml up -d
echo -e "\e[1;32m Done \e[0m"

#echo -e "\e[1;31m" Generating CA container for ca_madrid... "\e[0m"
#docker-compose -f docker/docker-compose-ca.yaml up -d ca_madrid
#echo -e "\e[1;32m Done \e[0m"
#
#echo -e "\e[1;31m" Generating CA container for ca_bogota... "\e[0m"
#docker-compose -f docker/docker-compose-ca.yaml up -d ca_bogota
#echo -e "\e[1;32m Done \e[0m"
#
#echo -e "\e[1;31m" Generating CA container for ca_berlin... "\e[0m"
#docker-compose -f docker/docker-compose-ca.yaml up -d ca_berlin
#echo -e "\e[1;32m Done \e[0m"
#
#echo -e "\e[1;31m" Generating CA container for ca_iebs... "\e[0m"
#docker-compose -f docker/docker-compose-ca.yaml up -d ca_iebs
#echo -e "\e[1;32m Done \e[0m"
#
#echo -e "\e[1;31m" Generating CA containers for ca_orderer... "\e[0m"
#docker-compose -f docker/docker-compose-ca.yaml up -d ca_orderer
#echo -e "\e[1;32m Done \e[0m"

# Registring and enrolling peers and user for madrid
echo -e "\e[1;31;40m Registring and enrolling org madrid... \e[0m"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createMadrid
echo -e "\e[1;32m Done \e[0m"

# Registring and enrolling peers and user for bogota
echo -e "\e[1;31;40m Registring and enrolling org bogota... \e[0m"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createBogota
echo -e "\e[1;32m Done \e[0m"

# Registring and enrolling peers and user for berlin
echo -e "\e[1;31;40m Registring and enrolling org berlin... \e[0m"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createBerlin
echo -e "\e[1;32m Done \e[0m"

# Registring and enrolling peers and user for iebs
echo -e "\e[1;31;40m Registring and enrolling org iebs... \e[0m"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createIebs
echo -e "\e[1;32m Done \e[0m"

# Registring and enrolling orderer
echo -e "\e[1;31;40m Registring and enrolling orderer... \e[0m"
sleep 2
. ./organizations/fabric-ca/registerEnroll.sh && createOrderer
echo -e "\e[1;32m Done \e[0m"

sudo chown -R $USER:$USER organizations

# Generation of the genesis block
echo -e "\e[1;31;40m Generating the genesis block... \e[0m"
export FABRIC_CFG_PATH=${PWD}/configtx
configtxgen -profile UniversidadesGenesis -outputBlock ./channel-artifacts/universidadeschannel.block -channelID universidadeschannel
echo -e "\e[1;32m Done \e[0m"

# Starting the network
echo -e "\e[1;31;40m Starting hyperledger network components... \e[0m"
docker-compose -f docker/docker-compose-universidades.yaml up -d
echo -e "\e[1;32m Done \e[0m"

# Joining the orders and peers to the channel
echo -e "\e[1;31;40m Joining orders & peers to the channel... \e[0m"
sleep 2
. ./scripts/join_channel.sh
echo -e "\e[1;32m Done \e[0m"

# Listing the channels
echo -e "\e[1;31;40m Listing channels... \e[0m"
sleep 2
. ./scripts/channel_list.sh
echo -e "\e[1;32m Done \e[0m"

# Installing and instantiating the chaincode
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/

# Check the peer version
echo -e "\e[1;33m Peer version... \e[0m"
peer version

# Package the chaincode
echo -e "\e[1;31;40m Packaging the chaincode ... \e[0m"
peer lifecycle chaincode package registroAlumnos.tar.gz --path ../asset-transfer-basic/chaincode-go/ --label registroAlumnos_1.0
echo -e "\e[1;32m Done \e[0m"

# Install the chaincode
echo -e "\e[1;31;40m Installing the chaincode... \e[0m"
sleep 2
. ./scripts/install_chaincode.sh
echo -e "\e[1;32m Done \e[0m"

# Query the installed chaincodes
echo -e "\e[1;31;40m Querying the installed chaincodes... \e[0m"
query_result=$(peer lifecycle chaincode queryinstalled)
package_id=$(echo "$query_result" | grep "Package ID:" | sed 's/.*: \([^,]*\),.*/\1/')
export CC_PACKACHAINCODE_PACKAGE_IDGE_ID="$package_id"
echo $CHAINCODE_PACKAGE_ID
echo -e "\e[1;32m Done \e[0m"

# Approve the chaincode for each organization
echo -e "\e[1;31;40m Approving the chaincode for each organization... \e[0m"
sleep 2
. ./scripts/approveChaincode.sh $CHAINCODE_PACKAGE_ID
echo -e "\e[1;32m Done \e[0m"

# Check the commit readiness of the chaincode
echo -e "\e[1;31;40m Checking the commit readiness of the chaincode... \e[0m"
peer lifecycle chaincode checkcommitreadiness --channelID universidadeschannel --name registroAlumnos --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem --output json
echo -e "\e[1;32m Done \e[0m"

# Commit the chaincode
echo -e "\e[1;31;40m Committing the chaincode... \e[0m"
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --channelID universidadeschannel --name registroAlumnos --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem --peerAddresses localhost:7051  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt  --peerAddresses localhost:10051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
echo -e "\e[1;32m Done \e[0m"

# Query the committed chaincode
echo -e "\e[1;31;40m Querying the committed chaincode... \e[0m"
peer lifecycle chaincode querycommitted --channelID universidadeschannel --name registroAlumnos --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
echo -e "\e[1;32m Done \e[0m"

# Invoking the chaincode to initialize the ledger
echo -e "\e[1;31;40m Invoking the chaincode to initialize the ledger... \e[0m"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem -C universidadeschannel -n registroAlumnos --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt --peerAddresses localhost:2051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt --peerAddresses localhost:4051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'
echo -e "\e[1;32m Done \e[0m"

# Hitting the couchdb to check the ledger
echo -e "\e[1;33m;40m Hitting the couchdb to check the ledger... \e[0m"
sleep 5
curl -X GET http://admin:adminpw@localhost:5984/universidadeschannel_ | jq .
echo -e "\e[1;32m Done \e[0m"

# Invoking the chaincode to get all students
echo -e "\e[1;33m;40m Invoking the chaincode to get all students... \e[0m"
sleep 5
peer chaincode query -C universidadeschannel -n registroAlumnos -c '{"Args":["GetAllStudents"]}' | jq .
echo -e "\e[1;32m Done \e[0m"

# Invoking the chaincode to register a student
echo -e "\e[1;33m;40m Invoking the chaincode to register a student... \e[0m"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem -C universidadeschannel -n registroAlumnos --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt --peerAddresses localhost:2051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt --peerAddresses localhost:4051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt -c '{"Args":["CreateStudent","student7","John","Doe","USA","madrid.universidades.com"]}'
echo -e "\e[1;32m Done \e[0m"

# Invoking the chaincode to get all students
echo -e "\e[1;33m;40m Invoking the chaincode to get all students... \e[0m"
sleep 5
peer chaincode query -C universidadeschannel -n registroAlumnos -c '{"Args":["GetAllStudents"]}' | jq .
echo -e "\e[1;32m Done \e[0m"

# Hitting the couchdb to check the ledger
echo -e "\e[1;33m;40m Hitting the couchdb to check the ledger... \e[0m"
curl -X GET http://admin:adminpw@localhost:5984/universidadeschannel_ | jq .
echo -e "\e[1;32m Done \e[0m"