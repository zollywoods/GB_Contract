// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


        // const RINKEBY_KEYHASH = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311'
        // const RINKEBY_LINKTOKEN = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709'
        // const RINKEBY_VRF_COORDINATOR = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B'



contract GBPalaces is Ownable, ERC721, VRFConsumerBase {

    bytes32 public keyHash;
    address public vrfCoordinator;
    uint256 internal fee;
    uint256 internal palaceFee;

    uint256 public randomResult;
    string public _baseTokenURI;

    
    uint256[] public palaces;


    mapping(bytes32 => address) internal requestToSender;


    //@dev constructor, sets the link variables, also should set the whitelist and rug owner list
    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash) public
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    ERC721("GrandBazaarPalace", "PALACE") {
        vrfCoordinator = _VRFCoordinator;
        keyHash = _keyhash;
        fee = 0.1 * 10**18; //0.1 LINK
        palaceFee = 0.046 ether;

        _baseTokenURI = "grandbazaarnft.io/palaces/";
    }   

    

    function getNumberOfPalaces()
    public view returns (uint256)
    {
        return palaces.length;
    }

    //@dev the mint function, a few requirements to mint 
    function requestNewPalace(bool isRugOwner, bool isWhiteList) 
    public payable returns(bytes32) {
        uint totalMinted = getNumberOfPalaces();
        require (totalMinted <= 7777, "This NFT is sold out!");
        if(isRugOwner == true){
            require(msg.value >= 0.028 ether, "Minting this NFT costs .025 ether"); 
        }
        else if(isWhiteList == true){
            require(msg.value >= 0.037 ether, "Minting this NFT costs .025 ether"); 
        }
        else{
           require(msg.value >= palaceFee, "Minting this NFT costs .03 ether"); 
        }

        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestToSender[requestId] = msg.sender;
        return requestId;
    }

    //@dev to be executed in requestNewPalace
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
    internal override{
        uint256 newId = palaces.length;

        palaces.push(randomNumber);

        _safeMint(requestToSender[requestId], newId);
    }

    function setBaseTokenURI(string memory URI) public onlyOwner {
        _baseTokenURI = URI;
    }

    function baseURI() public view virtual override returns (string memory) {
        // this might need to be _baseURI and need to change the variable to not be memory
        // the reason this may be is that im not using pragma >= 8
        return _baseTokenURI;
    }


    function setTokenURI(uint256 tokenId, string memory _tokenURI)  public onlyOwner{
        _setTokenURI(tokenId, _tokenURI);
    }

    //@dev in the case that ETH price skyrockets
    function setNewFee(uint256 _newFee) public onlyOwner {
        palaceFee = _newFee;
    }


    function withdraw()  public onlyOwner{
       msg.sender.transfer(address(this).balance);
        //@dev to be withdrawn in three wallets
    }

    function withdrawLink()  public onlyOwner{
       LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }



}
