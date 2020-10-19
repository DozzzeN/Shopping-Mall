pragma solidity ^0.4.23;

contract Product {
    string ipfs_address;
    address seller_address;

    constructor (
        string _ipfs_address
    ) public {
        ipfs_address = _ipfs_address;

        seller_address = msg.sender;
    }
}
