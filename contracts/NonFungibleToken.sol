pragma solidity 0.4.18;

import "./DetailedERC721.sol";
import "node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title NonFungibleToken
 *
 * Generic implementation for both required and optional functionality in
 * the ERC721 standard for non-fungible tokens.
 *
 * Heavily inspired by Decentraland's generic implementation:
 * https://github.com/decentraland/land/blob/master/contracts/BasicNFT.sol
 *
 * Standard Author: dete
 * Implementation Author: Nadav Hollander <nadav at dharma.io>
 */
contract NonFungibleToken is DetailedERC721 {
    using SafeMath for uint;

    string public name;
    string public symbol;

    uint public numTokensTotal;

    mapping(uint => address) internal tokenIdToOwner;
    // Unlike ERC20, a token in this implementation can only have one approved address
    // at one time. ERC721 specifies this, but perhaps we should allow tokens to have
    // multiple approved addresses?
    mapping(uint => address) internal tokenIdToApprovedAddress;
    mapping(uint => string) internal tokenIdToMetadata;
    mapping(address => uint[]) internal ownerToTokensOwned;
    mapping(uint => uint) internal tokenIdToOwnerArrayIndex;
    // To implement approveAll via Option 2, we need a mapping representing
    // 'owner' => '(array) addresses who are approved to transact all this owner's tokens'
    //
    // This name is quite long -- perhaps it would be useful to define a word to replace
    // an 'allTokensApprovedAddress'. 'agent', 'manager', 'executor'?
    mapping(address => address) internal ownerToAllTokensApprovedAddress;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved
    );

    modifier onlyExtantToken(uint _tokenId) {
        require(tokenIdToOwner[_tokenId] != address(0));
        _;
    }

    function name()
        public
        view
        returns (string _name)
    {
        return name;
    }

    function symbol()
        public
        view
        returns (string _symbol)
    {
        return symbol;
    }

    function totalSupply()
        public
        view
        returns (uint256 _totalSupply)
    {
        return numTokensTotal;
    }

    function balanceOf(address _owner)
        public
        view
        returns (uint _balance)
    {
        return ownerToTokensOwned[_owner].length;
    }

    function ownerOf(uint _tokenId)
        public
        view
        returns (address _owner)
    {
        return tokenIdToOwner[_tokenId];
    }

    function tokenMetadata(uint _tokenId)
        public
        view
        returns (string _infoUrl)
    {
        return tokenIdToMetadata[_tokenId];
    }

    function approve(address _to, uint _tokenId)
        public
        onlyExtantToken(_tokenId)
    {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);

        if (tokenIdToApprovedAddress[_tokenId] != address(0) ||
                _to != address(0)) {
            tokenIdToApprovedAddress[_tokenId] = _to;
            Approval(msg.sender, _to, _tokenId);
        }
    }

    /* 
    * Express approval for a third-party to transact with any of our NFTs.
    *
    */
    function approveAll(address _to)
        public
    {
        require(msg.sender != _to);

        if (ownerToAllTokensApprovedAddress[msg.sender] != address(0) ||
                _to != address(0)) {
            ownerToAllTokensApprovedAddress[msg.sender] = _to;
            Approval(msg.sender, _to);
        }
    }

    function transferFrom(address _from, address _to, uint _tokenId)
        public
        onlyExtantToken(_tokenId)
    {
        require(tokenIdToApprovedAddress[_tokenId] == msg.sender ||
            ownerToAllTokensApprovedAddress[_from] == msg.sender);
        require(tokenIdToOwner[_tokenId] == _from);

        _transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint _tokenId)
        public
        onlyExtantToken(_tokenId)
    {
        require(tokenIdToOwner[_tokenId] == msg.sender);

        _transfer(msg.sender, _to, _tokenId);
    }

    function tokenOfOwnerByIndex(address _owner, uint _index)
        public
        view
        returns (uint _tokenId)
    {
        return ownerToTokensOwned[_owner][_index];
    }

    function getOwnerTokens(address _owner)
        public
        view
        returns (uint[] _tokenIds)
    {
        return ownerToTokensOwned[_owner];
    }

    function implementsERC721()
        public
        view
        returns (bool _implementsERC721)
    {
        return true;
    }

    function getApproved(uint _tokenId)
        public
        view
        returns (address _approved)
    {
        // Is this condition correctly constructed?
        if (tokenIdToApprovedAddress[_tokenId] != address(0)) {
            return tokenIdToApprovedAddress[_tokenId];
        }
    }

    function _transfer(address _from, address _to, uint _tokenId)
        internal
    {
        require(_to != address(0));

        _clearTokenApproval(_tokenId);
        _removeTokenFromOwnersList(_from, _tokenId);
        _addTokenToOwnersList(_to, _tokenId);
        Transfer(msg.sender, _to, _tokenId);
    }

    function _clearTokenApproval(uint _tokenId)
        internal
    {
        tokenIdToApprovedAddress[_tokenId] = address(0);
        Approval(tokenIdToOwner[_tokenId], 0, _tokenId);
    }

    function _addTokenToOwnersList(address _owner, uint _tokenId)
        internal
    {
        ownerToTokensOwned[_owner].push(_tokenId);
        tokenIdToOwner[_tokenId] = _owner;
        tokenIdToOwnerArrayIndex[_tokenId] =
            ownerToTokensOwned[_owner].length - 1;
    }

    function _removeTokenFromOwnersList(address _owner, uint _tokenId)
        internal
    {
        uint length = ownerToTokensOwned[_owner].length;
        uint index = tokenIdToOwnerArrayIndex[_tokenId];
        uint swapToken = ownerToTokensOwned[_owner][length - 1];

        ownerToTokensOwned[_owner][index] = swapToken;
        tokenIdToOwnerArrayIndex[swapToken] = index;

        delete ownerToTokensOwned[_owner][length - 1];
        ownerToTokensOwned[_owner].length--;
    }
}
