#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=madrid
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/madrid.universidades.com/tlsca/tlsca.madrid.universidades.com-cert.pem
CAPEM=organizations/peerOrganizations/madrid.universidades.com/ca/ca.madrid.universidades.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/madrid.universidades.com/connection-madrid.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/madrid.universidades.com/connection-madrid.yaml

ORG=bogota
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/bogota.universidades.com/tlsca/tlsca.bogota.universidades.com-cert.pem
CAPEM=organizations/peerOrganizations/bogota.universidades.com/ca/ca.bogota.universidades.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/bogota.universidades.com/connection-bogota.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/bogota.universidades.com/connection-bogota.yaml

ORG=berlin
P0PORT=2051
CAPORT=2054
PEERPEM=organizations/peerOrganizations/berlin.universidades.com/tlsca/tlsca.berlin.universidades.com-cert.pem
CAPEM=organizations/peerOrganizations/berlin.universidades.com/ca/ca.berlin.universidades.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/berlin.universidades.com/connection-berlin.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/berlin.universidades.com/connection-berlin.yaml

ORG=iebs
P0PORT=4051
CAPORT=4054
PEERPEM=organizations/peerOrganizations/iebs.universidades.com/tlsca/tlsca.iebs.universidades.com-cert.pem
CAPEM=organizations/peerOrganizations/iebs.universidades.com/ca/ca.iebs.universidades.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/iebs.universidades.com/connection-iebs.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/iebs.universidades.com/connection-oriebsg2.yaml