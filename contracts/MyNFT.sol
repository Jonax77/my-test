// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyNFT is ERC1155, Ownable {

    struct NFTVoucher { 
    uint256 tokenId;   // The token id to be redeemed
    uint256 minPrice;  // The min price the caller has to pay in order to redeem
    bytes signature;  // The typed signature generated beforehand
} 

    bytes32[] signatures;
    uint256[] redeemed;
    uint256[] minPrices;
    IERC20 tokenAddress;

    // the base uri comes from tutorial of openzepplin
    constructor() ERC1155("https://game.example/api/item/{id}") {
        redeemed = [0, 0, 0];
        minPrices = [1 ether, 2 ether, 3 ether];

        // generate signatures when init
        for (uint i = 0; i < minPrices.length; i++) {
            bytes32 h = hash(i, minPrices[i]);
            signatures.push(h);
        }
    }

    function getSignature(uint256 tokenId) public view returns (bytes32) {
        require(tokenId > 0, "NFT doesn't exist.");
        require(tokenId <= minPrices.length, "NFT doesn't exist.");
        uint256 index = tokenId - 1;
        return signatures[index];
    }

    function settokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = IERC20(_tokenAddress);
    }

    function hash(uint256 _id, uint256 _minPrice) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_id, _minPrice));
    }

    // for testing in remix more conveniently, I divide the NFTVoucher XD
    function redeem(address redeemer, uint256 tokenId, uint256 minPrice, bytes32 signature)
        public
        payable
    {
        require(tokenId > 0, "NFT doesn't exist.");
        require(tokenId <= minPrices.length, "NFT doesn't exist.");

        uint index = tokenId - 1;
        require(signature == signatures[index], "Wrong signature!");
        require(redeemed[index] == 0, "Not available anymore!");
        tokenAddress.transferFrom(msg.sender, address(this), minPrice);
        
        _mint(redeemer, tokenId, 1, "");
        redeemed[index] = 1;
    }

    
}
/*
    bonus: support multi erc-20 payment

    do following adjustment in code

    IERC20[] public allowedToken;
    mapping(IERC20 => bool) public exists;

    function addCurrency(address _paytoken) public onlyOwner {
        IERC20 paytoken = IERC20(_paytoken);
        allowedToken.push(paytoken);
        exists[paytoken] = true;
    }

    function redeem(address redeemer, NFTVoucher calldata voucher, IERC20 paytoken)
        public
        payable
    {
        require(exists[paytoken] == true, "Invalid token to pay");
        
        _;
    }

*/