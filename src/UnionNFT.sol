// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract UnionNFT is ERC721Upgradeable, OwnableUpgradeable {
  string public baseURI;
  uint256 public nextTokenId;
  uint256 public maxSupply;
  // max mint per user
  uint256 public maxMintPerUser;
  // minted tokens of user
  mapping(address => uint256) public mintedTokens;

  event BaseURIChanged(string baseURI);
  event MaxSupplyChanged(uint256 maxSupply);
  event MaxMintPerUserChanged(uint256 maxMintPerUser);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev initialize the contract
   * @param _owner - Address of the owner
   * @param _name - name
   * @param _symbol - symbol
   * @param _baseURI - base URI
   * @param _maxSupply - max supply
   * @param _maxMintPerUser - max mint per user
   */
  function initialize(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    uint256 _maxSupply,
    uint256 _maxMintPerUser
  ) public initializer {
    __Ownable_init(_owner);
    __ERC721_init(_name, _symbol);
    baseURI = _baseURI;
    nextTokenId = 1;
    maxSupply = _maxSupply;
    maxMintPerUser = _maxMintPerUser;
  }

  function mint() public returns (uint256) {
    require(nextTokenId <= maxSupply, "UnionNFT: max supply reached");
    require(
      mintedTokens[msg.sender] < maxMintPerUser,
      "UnionNFT: max mint per user reached"
    );
    ++mintedTokens[msg.sender];
    uint256 tokenId = nextTokenId++;
    _mint(msg.sender, tokenId);
    return tokenId;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
    emit BaseURIChanged(_baseURI);
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    require(
      _maxSupply >= nextTokenId,
      "UnionNFT: new max supply should be greater than the current supply"
    );
    maxSupply = _maxSupply;
    emit MaxSupplyChanged(_maxSupply);
  }

  function setMaxMintPerUser(uint256 _maxMintPerUser) external onlyOwner {
    maxMintPerUser = _maxMintPerUser;
    emit MaxMintPerUserChanged(_maxMintPerUser);
  }
}
