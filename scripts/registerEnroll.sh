#!/bin/bash

function createMadrid() {
  echo -e "\e[1;33mEnrolling the CA admin\e[0m"
  mkdir -p organizations/peerOrganizations/madrid.universidades.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/madrid.universidades.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-madrid --tls.certfiles "${PWD}/organizations/fabric-ca/madrid/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-madrid.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-madrid.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-madrid.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-madrid.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/madrid.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mRegistering peer0\e[0m"
  set -x
  fabric-ca-client register --caname ca-madrid --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/madrid/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering user\e[0m"
  set -x
  fabric-ca-client register --caname ca-madrid --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/madrid/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering the org admin\e[0m"
  set -x
  fabric-ca-client register --caname ca-madrid --id.name madridadmin --id.secret madridadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/madrid/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mGenerating the peer0 msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-madrid -M "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/msp" --csr.hosts peer0.madrid.universidades.com --tls.certfiles "${PWD}/organizations/fabric-ca/madrid/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the peer0-tls certificates\e[0m"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-madrid -M "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls" --enrollment.profile tls --csr.hosts peer0.madrid.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/madrid/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/server.key"

  mkdir -p "${PWD}/organizations/peerOrganizations/madrid.universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/madrid.universidades.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/peerOrganizations/madrid.universidades.com/tlsca"
  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/madrid.universidades.com/tlsca/tlsca.madrid.universidades.com-cert.pem"

  mkdir -p "${PWD}/organizations/peerOrganizations/madrid.universidades.com/ca"
  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/madrid.universidades.com/ca/ca.madrid.universidades.com-cert.pem"

  echo -e "\e[1;33mGenerating the user msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-madrid -M "${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/User1@madrid.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/madrid/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/User1@madrid.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the org admin msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://madridadmin:madridadminpw@localhost:7054 --caname ca-madrid -M "${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/madrid/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/madrid.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp/config.yaml"
}

function createBogota() {
  echo -e "\e[1;33mEnrolling the CA admin\e[0m"
  mkdir -p organizations/peerOrganizations/bogota.universidades.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/bogota.universidades.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-bogota --tls.certfiles "${PWD}/organizations/fabric-ca/bogota/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-bogota.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-bogota.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-bogota.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-bogota.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/bogota.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mRegistering peer0\e[0m"
  set -x
  fabric-ca-client register --caname ca-bogota --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/bogota/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering user\e[0m"
  set -x
  fabric-ca-client register --caname ca-bogota --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/bogota/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering the org admin\e[0m"
  set -x
  fabric-ca-client register --caname ca-bogota --id.name bogotaadmin --id.secret bogotaadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/bogota/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mGenerating the peer0 msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-bogota -M "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/msp" --csr.hosts peer0.bogota.universidades.com --tls.certfiles "${PWD}/organizations/fabric-ca/bogota/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the peer0-tls certificates\e[0m"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-bogota -M "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls" --enrollment.profile tls --csr.hosts peer0.bogota.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/bogota/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/server.key"

  mkdir -p "${PWD}/organizations/peerOrganizations/bogota.universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/bogota.universidades.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/peerOrganizations/bogota.universidades.com/tlsca"
  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/bogota.universidades.com/tlsca/tlsca.bogota.universidades.com-cert.pem"

  mkdir -p "${PWD}/organizations/peerOrganizations/bogota.universidades.com/ca"
  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/bogota.universidades.com/ca/ca.bogota.universidades.com-cert.pem"

  echo -e "\e[1;33mGenerating the user msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-bogota -M "${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/User1@bogota.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/bogota/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/User1@bogota.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the org admin msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://bogotaadmin:bogotaadminpw@localhost:8054 --caname ca-bogota -M "${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/bogota/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/bogota.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp/config.yaml"
}

function createOrderer() {
  echo -e "\e[1;33mEnrolling the CA admin\e[0m"
  mkdir -p organizations/ordererOrganizations/universidades.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/universidades.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml"

  echo -e "\e[1;33mRegistering orderer\e[0m"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering the orderer admin\e[0m"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mGenerating the orderer msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp" --csr.hosts orderer.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the orderer-tls certificates\e[0m"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls" --enrollment.profile tls --csr.hosts orderer.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key"

  mkdir -p "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem"

  mkdir -p "${PWD}/organizations/ordererOrganizations/universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem"

  echo -e "\e[1;33mGenerating the admin msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp/config.yaml"
}

function createBerlin() {
  echo -e "\e[1;33mEnrolling the CA admin\e[0m"
  mkdir -p organizations/peerOrganizations/berlin.universidades.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/berlin.universidades.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:2054 --caname ca-berlin --tls.certfiles "${PWD}/organizations/fabric-ca/berlin/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-2054-ca-berlin.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-2054-ca-berlin.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-2054-ca-berlin.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-2054-ca-berlin.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/berlin.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mRegistering peer0\e[0m"
  set -x
  fabric-ca-client register --caname ca-berlin --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/berlin/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering user\e[0m"
  set -x
  fabric-ca-client register --caname ca-berlin --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/berlin/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering the org admin\e[0m"
  set -x
  fabric-ca-client register --caname ca-berlin --id.name berlinadmin --id.secret berlinadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/berlin/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mGenerating the peer0 msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:2054 --caname ca-berlin -M "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/msp" --csr.hosts peer0.berlin.universidades.com --tls.certfiles "${PWD}/organizations/fabric-ca/berlin/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the peer0-tls certificates\e[0m"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:2054 --caname ca-berlin -M "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls" --enrollment.profile tls --csr.hosts peer0.berlin.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/berlin/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/server.key"

  mkdir -p "${PWD}/organizations/peerOrganizations/berlin.universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/berlin.universidades.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/peerOrganizations/berlin.universidades.com/tlsca"
  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/berlin.universidades.com/tlsca/tlsca.berlin.universidades.com-cert.pem"

  mkdir -p "${PWD}/organizations/peerOrganizations/berlin.universidades.com/ca"
  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/berlin.universidades.com/ca/ca.berlin.universidades.com-cert.pem"

  echo -e "\e[1;33mGenerating the user msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:2054 --caname ca-berlin -M "${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/User1@berlin.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/berlin/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/User1@berlin.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the org admin msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://berlinadmin:berlinadminpw@localhost:2054 --caname ca-berlin -M "${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/Admin@berlin.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/berlin/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/berlin.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/Admin@berlin.universidades.com/msp/config.yaml"
}

function createIebs() {
  echo -e "\e[1;33mEnrolling the CA admin\e[0m"
  mkdir -p organizations/peerOrganizations/iebs.universidades.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/iebs.universidades.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:4054 --caname ca-iebs --tls.certfiles "${PWD}/organizations/fabric-ca/iebs/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-4054-ca-iebs.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-4054-ca-iebs.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-4054-ca-iebs.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-4054-ca-iebs.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mRegistering peer0\e[0m"
  set -x
  fabric-ca-client register --caname ca-iebs --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/iebs/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering user\e[0m"
  set -x
  fabric-ca-client register --caname ca-iebs --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/iebs/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mRegistering the org admin\e[0m"
  set -x
  fabric-ca-client register --caname ca-iebs --id.name iebsadmin --id.secret iebsadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/iebs/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo -e "\e[1;33mGenerating the peer0 msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:4054 --caname ca-iebs -M "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp" --csr.hosts peer0.iebs.universidades.com --tls.certfiles "${PWD}/organizations/fabric-ca/iebs/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the peer0-tls certificates\e[0m"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:4054 --caname ca-iebs -M "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls" --enrollment.profile tls --csr.hosts peer0.iebs.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/iebs/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/server.key"

  mkdir -p "${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/peerOrganizations/iebs.universidades.com/tlsca"
  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/iebs.universidades.com/tlsca/tlsca.iebs.universidades.com-cert.pem"

  mkdir -p "${PWD}/organizations/peerOrganizations/iebs.universidades.com/ca"
  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/iebs.universidades.com/ca/ca.iebs.universidades.com-cert.pem"

  echo -e "\e[1;33mGenerating the user msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:4054 --caname ca-iebs -M "${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/User1@iebs.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/iebs/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/User1@iebs.universidades.com/msp/config.yaml"

  echo -e "\e[1;33mGenerating the org admin msp\e[0m"
  set -x
  fabric-ca-client enroll -u https://iebsadmin:iebsadminpw@localhost:4054 --caname ca-iebs -M "${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/iebs/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp/config.yaml"
}