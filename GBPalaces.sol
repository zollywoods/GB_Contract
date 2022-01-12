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

    struct Palace{
        uint256 background;
        uint256 building;
        uint256 domeOne;
        uint256 domeTwo;
        uint256 domeThree;
        uint256 fountainAndGarden;
        uint256 railingAndBalcony;
        uint256 tree;
        uint256 pillar;
    }

    
    Palace[] public palaces;

    mapping(bytes32 => address) internal requestToSender;

    mapping(address => bool) internal rugOwners;


    // @dev function for adding rugowners to rugOwners mapping
    function addRugOwners(address _owner) public onlyOwner{
        rugOwners[_owner]=true;
    }

    //@dev function for checking if minter is a rug owner
    function contains(address _owner) public view returns (bool){
        return rugOwners[_owner];
    }


    //@dev constructor, sets the link variables, also should set the whitelist and rug owner list
    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash) public
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    ERC721("GrandBazaarPalace", "PALACE") {
        vrfCoordinator = _VRFCoordinator;
        keyHash = _keyhash;
        fee = 0.1 * 10**18; //0.1 LINK
        palaceFee = 30000000000000000;
    }   


    function getNumberOfPalaces()
    public view returns (uint256)
    {
        return palaces.length;
    }

    //@dev the mint function, a few requirements to mint 
    function requestNewPalace() 
    public payable returns(bytes32) {
        uint totalMinted = getNumberOfPalaces();
        require (totalMinted <= 7777, "This NFT is sold out!");
        if(contains(msg.sender)){
            require(msg.value >= (palaceFee - 7500000000000000), "Minting this NFT costs .025 ether"); 
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

        uint256 background = (randomNumber % 1000);

        uint256 building = ((randomNumber % 1000000) / 1000);

        uint256 domeOne = ((randomNumber % 1000000000) / 1000000);

        uint256 domeTwo = ((randomNumber % 1000000000000) / 1000000000);

        uint256 domeThree = ((randomNumber % 1000000000000000) / 1000000000000);

        uint256 fountainAndGarden =  ((randomNumber % 1000000000000000000) / 1000000000000000);

        uint256 railingAndBalcony =  ((randomNumber % 1000000000000000000000) / 1000000000000000000);

        uint256 tree =  ((randomNumber % 1000000000000000000000000) / 1000000000000000000000);

        uint256 pillar =  ((randomNumber % 1000000000000000000000000000) / 1000000000000000000000000);


        palaces.push(
            Palace(
                background,
                building,
                domeOne,
                domeTwo,
                domeThree,
                fountainAndGarden,
                railingAndBalcony,
                tree,
                pillar
            )
        );


        _safeMint(requestToSender[requestId], newId);
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