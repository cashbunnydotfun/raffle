

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {
    
    function toHexChar(uint8 byteValue) internal pure returns (bytes memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory result = new bytes(1);
        result[0] = alphabet[byteValue];
        return result;
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory hexString = new bytes(42);
        hexString[0] = "0";
        hexString[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            uint8 byteValue = uint8(_bytes[i]);
            bytes memory stringValue = toHexChar(byteValue / 16);
            hexString[i * 2 + 2] = stringValue[0];
            stringValue = toHexChar(byteValue % 16);
            hexString[i * 2 + 3] = stringValue[0];
        }
        return string(hexString);
    }
    

    function abs(int x) pure private returns (uint) {
        return uint(x >= 0 ? x : -x);
    }    
}
