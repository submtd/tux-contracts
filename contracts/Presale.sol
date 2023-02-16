// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Presale is ERC721 {

    /**
     * Contract constructor.
     */
    constructor() ERC721("Tux Presale", "TUXP") {}
}
