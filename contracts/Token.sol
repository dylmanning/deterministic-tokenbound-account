// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
//6551 references
import "reference/src/interfaces/IERC6551Registry.sol";

interface ITokenImplementation {
    function execute(
        address to,
        address contr,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable returns (bytes memory result);
}

contract Token is
    ERC721,
    Ownable,
    ERC721Enumerable,
    ERC721Pausable,
    ERC721Burnable
{
    uint256 private _nextTokenId;
    uint public immutable chainId = block.chainid;

    address public immutable implementation;
    address public immutable tokenContract = address(this);

    bytes32 salt = 0;

    IERC6551Registry public immutable REGISTRY;

    constructor(
        address _implementation,
        address _registry
    ) ERC721("Token", "DTBA") Ownable(msg.sender) {
        implementation = _implementation;
        REGISTRY = IERC6551Registry(_registry);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint() public {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    function getAccount(uint tokenId) public view returns (address) {
        return
            REGISTRY.account(
                implementation,
                salt,
                chainId,
                tokenContract,
                tokenId
            );
    }

    function createAccount(uint tokenId) public returns (address) {
        return
            REGISTRY.createAccount(
                implementation,
                salt,
                chainId,
                tokenContract,
                tokenId
            );
    }

    function call(uint tokenId, address contrac) public {
        address accountAddress = this.getAccount(tokenId);
        ITokenImplementation(accountAddress).execute(
            msg.sender,
            contrac,
            0.0 ether,
            abi.encodeWithSignature("call()"),
            0
        );
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
