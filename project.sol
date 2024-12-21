// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TokenizedCollectibleCardGame is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Card struct to store card attributes
    struct Card {
        string name;
        uint256 attack;
        uint256 defense;
        string cardType; // e.g., "Creature", "Spell", "Artifact"
        uint256 rarity; // 1: Common, 2: Uncommon, 3: Rare, 4: Mythic
        bool isForSale;
        uint256 price;
    }

    // Mapping from token ID to Card
    mapping(uint256 => Card) public cards;
    
    // Base URI for metadata
    string private _baseURIextended;

    // Events
    event CardMinted(uint256 indexed tokenId, address owner, string name);
    event CardListedForSale(uint256 indexed tokenId, uint256 price);
    event CardPurchased(uint256 indexed tokenId, address from, address to, uint256 price);

    constructor() ERC721("TokenizedCollectibleCardGame", "TCCG") Ownable(msg.sender) {}

    // Mint new card
    function mintCard(
        address player,
        string memory name,
        uint256 attack,
        uint256 defense,
        string memory cardType,
        uint256 rarity
    ) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newCardId = _tokenIds.current();

        _safeMint(player, newCardId);
        
        cards[newCardId] = Card({
            name: name,
            attack: attack,
            defense: defense,
            cardType: cardType,
            rarity: rarity,
            isForSale: false,
            price: 0
        });

        emit CardMinted(newCardId, player, name);
        return newCardId;
    }

    // List card for sale
    function listCardForSale(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Only card owner can list for sale");
        require(price > 0, "Price must be greater than 0");

        cards[tokenId].isForSale = true;
        cards[tokenId].price = price;

        emit CardListedForSale(tokenId, price);
    }

    // Purchase card
    function purchaseCard(uint256 tokenId) public payable {
        Card memory card = cards[tokenId];
        require(card.isForSale, "Card is not for sale");
        require(msg.value >= card.price, "Insufficient payment");
        
        address seller = ownerOf(tokenId);
        
        // Transfer ownership
        _transfer(seller, msg.sender, tokenId);
        
        // Transfer payment to seller
        payable(seller).transfer(msg.value);
        
        // Update card status
        cards[tokenId].isForSale = false;
        cards[tokenId].price = 0;

        emit CardPurchased(tokenId, seller, msg.sender, msg.value);
    }

    // Get card details
    function getCard(uint256 tokenId) public view returns (Card memory) {
        require(_ownerOf(tokenId) != address(0), "Card does not exist");
        return cards[tokenId];
    }

    // Set base URI for metadata
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    // Required overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }
}