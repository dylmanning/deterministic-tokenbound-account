// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
//6551 references
import "reference/src/interfaces/IERC6551Account.sol";
import "reference/src/interfaces/IERC6551Executable.sol";
import "reference/src/lib/ERC6551AccountLib.sol";

import "hardhat/console.sol";

contract TokenImplementation is IERC165, IERC6551Account, IERC721Receiver {
    uint256 public state;

    error TokenCannotAccept20s();
    error TokenDoesNotAccept721s();
    error TokenDoesNotAccept1155s();
    error TokenCannotExecuteCalls();

    receive() external payable {
        revert TokenCannotAccept20s();
    }

    function execute(
        address to,
        address contr,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable virtual returns (bytes memory result) {
        console.log("to %s value %s operation %s", to, value, operation);
        console.log("sender %s", msg.sender);
        require(_isValidSigner(to), "Invalid signer");
        // require(operation == 0, "Only call operations are supported");

        ++state;

        bool success;
        (success, result) = contr.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function isValidSigner(
        address signer,
        bytes calldata
    ) external view virtual returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view virtual returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId;
    }

    function token() public view virtual returns (uint256, address, uint256) {
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function owner() public view virtual returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function _isValidSigner(
        address signer
    ) internal view virtual returns (bool) {
        console.log("owner %s", owner());
        return signer == owner();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert TokenDoesNotAccept721s();
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        revert TokenDoesNotAccept1155s();
    }
}
