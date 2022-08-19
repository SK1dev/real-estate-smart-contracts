// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RealEstate is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("RealEstate", "RST") {}

    //Map of address containing the NFT token IDs array (get all nft ids for a given address)
    mapping(address=>uint256[]) private propertyOwnersMap;

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        //Save this token id to the propertyOwnersMap
        propertyOwnersMap[to].push(tokenId);

        _tokenIdCounter.increment();

    }

    // The following 2 functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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

    /**
     * @dev function to get list of all tokenIDs belonging to a specific owner address
     */
    function getAllTokenIDs(address propertyOwner) public view returns(uint256[] memory tokenIds){
        return propertyOwnersMap[propertyOwner];
    }
}