// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IInvestorVault {
    function addInvestor ( address investor_, uint256 amount_ ) external;
    function addressBook (  ) external view returns ( address );
    function approve ( address to, uint256 tokenId ) external;
    function available ( uint256 tokenId_ ) external view returns ( uint256 );
    function balanceOf ( address owner ) external view returns ( uint256 );
    function getApproved ( uint256 tokenId ) external view returns ( address );
    function invested ( uint256 ) external view returns ( uint256 );
    function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
    function name (  ) external view returns ( string memory );
    function owner (  ) external view returns ( address );
    function ownerOf ( uint256 tokenId ) external view returns ( address );
    function renounceOwnership (  ) external;
    function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
    function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory data ) external;
    function setAddressBook ( address address_ ) external;
    function setApprovalForAll ( address operator, bool approved ) external;
    function setup (  ) external;
    function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
    function symbol (  ) external view returns ( string memory );
    function tokenURI ( uint256 tokenId_ ) external view returns ( string memory );
    function totalInvested (  ) external view returns ( uint256 );
    function totalOutstanding (  ) external view returns ( uint256 );
    function totalRepaid (  ) external view returns ( uint256 );
    function totalWithdrawn (  ) external view returns ( uint256 );
    function transferFrom ( address from, address to, uint256 tokenId ) external;
    function transferOwnership ( address newOwner ) external;
    function withdraw ( uint256 tokenId_ ) external;
    function withdrawn ( uint256 ) external view returns ( uint256 );
}
