pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

contract Transfer {
    function bytesToUint(bytes memory b) public pure returns (uint){
        uint number;
        for (uint i = 0; i < b.length; i++) {
            number = number + uint8(b[i]) * (2 ** (8 * (b.length - (i + 1))));
        }
        return number;
    }

    function toBytes0(uint _num) public pure returns (bytes memory _ret) {
        assembly {
            _ret := mload(0x10)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _num)
        }
    }

    function byte32ToString(bytes32 b) public pure returns (string) {
        bytes memory names = new bytes(b.length);
        for (uint i = 0; i < b.length; i++) {
            names[i] = b[i];
        }
        return string(names);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    //["pen","2","0xc7eaC4D0fD7f2700cc8e0ADD2F6428310D118b02","
    function enc(string[4] input) public pure returns (bytes32[4] result){
        bytes32 k = 0x0123456789;
        result[0] = k ^ stringToBytes32(input[0]);
        result[0] = k ^ stringToBytes32(input[1]);
        result[0] = k ^ stringToBytes32(input[2]);
        result[0] = k ^ stringToBytes32(input[3]);
    }

    //"public_key_of_ttp","0x131d07100806087f1f0d1c7f00143b16174c1f10116365737366756c6c792100"
    //result0:"0x6368657c616557147a744310664b4f62674c1f10116365737366756c6c792100"
    function enc0(string k, bytes32 input) public pure returns (bytes32 result0){
        result0 = stringToBytes32(k) ^ input;
    }

    //["public_key_of_express","public_key_of_seller","000001"],"private_key_of_express"
    //"0x404259465145655f6b65795f6f664978646e7264007300000000000000000000"
    function enc1(string[3] input, string k) public pure returns (bytes32 result1){
        result1 = stringToBytes32(input[0]) ^ stringToBytes32(input[1])
        ^ stringToBytes32(input[2]) ^ stringToBytes32(k);
    }

    /*
    ["0x1b00170000000000000000000000000000000000000000000000000000000000",
    "0x5965790000000000000000000000000000000000000000000000000000000000",
    "0x5b1d1a3765614334443066443766323730306363386530414444324636343238"],
    "public_key_of_buyer"
    */

    //0x6b75756c69635f6b65795f6f665f627579657200000000000000000000000000,0x29101b6c69635f6b65795f6f665f627579657200000000000000000000000000,0x2b68785b0c021c5f2149392b5139504249551163386530414444324636343238"
    function enc2(bytes32[3] input, string k) public pure returns (bytes32[3] result2){
        result2[0] = input[0] ^ stringToBytes32(k);
        result2[1] = input[1] ^ stringToBytes32(k);
        result2[2] = input[2] ^ stringToBytes32(k);
    }

    //["pen","2","0xc7eaC4D0fD7f2700cc8e0ADD2F6428310D118b02"]
    //"private_key_of_buyer"
    //sig="0x026f64410415266b2f551f1b58006d5545490611386530414444324636343238"
    function sig(string[3] input, string sk_b) public pure returns (string sig) {
        bytes32 order = stringToBytes32(input[0]) ^ stringToBytes32(input[1]) ^ stringToBytes32(input[2]);
        bytes32 _sig = order ^ stringToBytes32(sk_b);
        sig = byte32ToString(_sig);
    }

    //"confirm the order successfully!","private_key_of_seller"
    //sig0:"0x131d07100806087f1f0d1c7f00143b16174c1f10116365737366756c6c792100"
    function sig0(string input, string sk_b) public pure returns (bytes32 sig0) {
        sig0 = stringToBytes32(input) ^ stringToBytes32(sk_b);
    }

    //"key","public_key_of_seller"
    //key:"0x6b65790000000000000000000000000000000000000000000000000000000000"
    //pk_s:"0x7075626c69635f6b65795f6f665f73656c6c6572000000000000000000000000"
    //enckey:"0x1b101b6c69635f6b65795f6f665f73656c6c6572000000000000000000000000"
    function encKey(string key, string pk_s) public pure returns (bytes32 enckey) {
        enckey = stringToBytes32(key) ^ stringToBytes32(pk_s);
    }

    function _xor(bytes32 a, bytes32 b) public pure returns (bytes32 c) {
        c = a ^ b;
    }
}
