// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

// Una vez el contrato se despliega tenemos que
// ejecutar la funcion safeMint con tu address
contract CardNFT is AutomationCompatibleInterface, VRFConsumerBaseV2, ConfirmedOwner, ERC721, ERC721URIStorage  {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    //Variable para  almacenar ultimo numero
    uint256 public lastRandomNumber;

    //mapping para guardar las ipfs uri correspondiente por Token ID
    mapping(uint256 => uint256) public s_NumerosIPFS;

    //Estos valores sonn estaticos pero el NFT ira apuntando
    // a cualquier de estos valores a medida que va evolucionando
    string[] IpfsUriUno = [
        "https://ipfs.io/ipfs/QmYY3McbLiy9AKbt66fnA6xUyRwYqzpx2c6P81ZriSQSRj/car_1.json",
        "https://ipfs.io/ipfs/QmYY3McbLiy9AKbt66fnA6xUyRwYqzpx2c6P81ZriSQSRj/car_2.json",
        "https://ipfs.io/ipfs/QmYY3McbLiy9AKbt66fnA6xUyRwYqzpx2c6P81ZriSQSRj/car_3.json"
    ];

    string[] IpfsUriDos = [
        "https://ipfs.io/ipfs/QmdFtBi6wM6rAxetfCDdgrvxxyMjUFjWjCVsprTtqjWLQ7/car_1.json",
        "https://ipfs.io/ipfs/QmdFtBi6wM6rAxetfCDdgrvxxyMjUFjWjCVsprTtqjWLQ7/car_2.json",
        "https://ipfs.io/ipfs/QmdFtBi6wM6rAxetfCDdgrvxxyMjUFjWjCVsprTtqjWLQ7/car_3.json"
    ];

    string[] IpfsUriTres = [
        "https://ipfs.io/ipfs/QmNSPoBuCuKtf6ihBdaxmgHvruQWgvVgSo8M2d6QDWePyT/car_1.json",
        "https://ipfs.io/ipfs/QmNSPoBuCuKtf6ihBdaxmgHvruQWgvVgSo8M2d6QDWePyT/car_2.json",
        "https://ipfs.io/ipfs/QmNSPoBuCuKtf6ihBdaxmgHvruQWgvVgSo8M2d6QDWePyT/car_3.json"
    ];

    //////////////////////////////////////
    // ***** Inicia Configuracion VRF *****//////
    //////////////////////////////////////
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        uint256 num;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint32 callbackGasLimit = 500000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 2;
    //////////////////////////////////////
    // ***** FIN - Configuracion VRF *****//////
    //////////////////////////////////////

    // Configuracion AUTOMATION
    uint interval;
    uint lastTimeStamp;

    constructor(uint _interval, uint64 subscriptionId) ERC721("CardNFT", "dNFT") VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
        ConfirmedOwner(msg.sender){
        interval = _interval;
        lastTimeStamp = block.timestamp;
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        s_subscriptionId = subscriptionId;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;        
    }

    function performUpkeep(bytes calldata /* performData */) external override  {        
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;

            uint counter = _tokenIdCounter.current();

            for (uint256 index = 0; index < counter; index++) {            
                if(carLevel(index) < 2){
                    pympMyRide(index);
                    break;
                }                
            }            
        }        
    }

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);  

        if(lastRandomNumber == 1){
            _setTokenURI(tokenId, IpfsUriUno[0]);
            s_NumerosIPFS[tokenId] = 1;

        }else if(lastRandomNumber == 2){
            _setTokenURI(tokenId, IpfsUriDos[0]);
            s_NumerosIPFS[tokenId] = 2;

        }else if(lastRandomNumber == 3){
            _setTokenURI(tokenId, IpfsUriTres[0]);
            s_NumerosIPFS[tokenId] = 3;
        }          
    }

    function pympMyRide(uint256 _tokenId) public{
        require(carLevel(_tokenId) < 2, "Maximo nivel alcanzado!");
        //if(carLevel(_tokenId) >= 2) {return;}    
        string memory newUri = "";
        // obtiene el valor actual del auto y le suma 1
        uint256 newVal = carLevel(_tokenId) + 1;
        // store the new URI
        if(s_NumerosIPFS[_tokenId] == 1){
            newUri = IpfsUriUno[newVal];
        }
        else if(s_NumerosIPFS[_tokenId] == 2){
            newUri = IpfsUriDos[newVal];
        }
        else if(s_NumerosIPFS[_tokenId] == 3){
            newUri = IpfsUriTres[newVal];
        }
        
        //Update the URI
        _setTokenURI(_tokenId, newUri);
    }

    // helper functions
    //
    function carLevel(uint256 _tokenId) public view returns(uint256){
        string memory _uri = tokenURI(_tokenId);

        uint result;
        uint lengthIPFS = 0;

        if(s_NumerosIPFS[_tokenId] == 1){
            lengthIPFS = IpfsUriUno.length;
        }
        else if(s_NumerosIPFS[_tokenId] == 2){
            lengthIPFS = IpfsUriDos.length;
        }
        else if(s_NumerosIPFS[_tokenId] == 3){
            lengthIPFS = IpfsUriTres.length;
        }
        
        for (uint256 index = 0; index < lengthIPFS; index++) {    
            if(s_NumerosIPFS[_tokenId] == 1){
                if(keccak256(abi.encodePacked(IpfsUriUno[index])) == keccak256(abi.encodePacked(_uri)))
                result = index;
            }
            else if(s_NumerosIPFS[_tokenId] == 2){
                if(keccak256(abi.encodePacked(IpfsUriDos[index])) == keccak256(abi.encodePacked(_uri)))
                result = index;
            }
            else if(s_NumerosIPFS[_tokenId] == 3){
                if(keccak256(abi.encodePacked(IpfsUriTres[index])) == keccak256(abi.encodePacked(_uri)))
                result = index;
            }        
        }
        return result;
    }

    // FUNCTIONS NFT
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    // *** VRF EMPIEZA AQUI ***
    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false, num: 0});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        uint256 randomNum = (_randomWords[0] % 3) + 1;
        s_requests[_requestId].num = randomNum;
        lastRandomNumber = randomNum;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
