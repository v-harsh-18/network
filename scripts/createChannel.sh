. scripts/envVar.sh

CHANNEL_NAME="$1"
DELAY="$3"
MAX_RETRY="$5"

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createGenesisBlock(){
	configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
}

createChannel()
{
	setGlobals 1
	local rc=1
	local COUNTER=$MAX_RETRY
	local temp=0

	while [ $rc -ne 0 ] ; do
		sleep $DELAY

    	osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		res=$?
		let rc=$res
		COUNTER=$(expr $COUNTER -1)
	done

	cat log.txt
}

joinChannel() {
  ORG=$1
  FABRIC_CFG_PATH=$PWD/configtx/

  export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0  ] ; do
    sleep 5
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
}

FABRIC_CFG_PATH=${PWD}/configtx
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

createGenesisBlock
createChannel

joinChannel 1