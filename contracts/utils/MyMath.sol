// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
library MyMath {
    function safePower(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0 || base == 0) return 0;
        if (exponent == 1) return base;
        bool ok;
        uint256 result = 1;
        while (exponent > 0) {
            // 如果指数是奇数，则将当前基数乘到结果中
            if (exponent % 2 == 1) {
                (ok,result) = Math.tryMul(result, base);
                require(ok, "mul1Error");
            }
            (ok,base) = Math.tryMul(base, base);
            require(ok, "mul2Error");
            (ok,exponent) = Math.tryDiv(exponent, 2);
            require(ok, "exponentError");
        }
        return result;
    }

    function calculatePower(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        }
        bool ok;
        uint256 result = 1;
        for (uint256 i = 0; i < exponent; i++) {
            (ok, result) = Math.tryMul(result, base);
            require(ok, "mulError");
        }

        return result;
    }

    function toBytes(uint256 n) internal pure returns (bytes memory) {
        // Zero encodes as an empty byte slice.
        if (n == 0) {
            return "";
        }

        // Take the absolute value and keep track of whether it was originally
        // negative.
        bool isNegative = false;

        // Encode to little endian.  The maximum number of encoded bytes is 9
        // (8 bytes for max int64 plus a potential byte for sign extension).
        bytes memory result = new bytes(0);
        while(n > 0) {
            uint8 v = SafeCast.toUint8(uint256(n & 0xff));
            result = abi.encodePacked(result, v);
            n >>= 8;
        }
        // When the most significant byte already has the high bit set, an
        // additional high byte is required to indicate whether the number is
        // negative or positive.  The additional byte is removed when converting
        // back to an integral and its high bit is used to denote the sign.
        //
        // Otherwise, when the most significant byte does not already have the
        // high bit set, use it to indicate the value is negative, if needed.
        if (result[result.length - 1] & bytes1(0x80) != 0) {
            bytes1 extraByte = bytes1(0x00);
            if (isNegative) {
                extraByte = 0x80;
            }
            result = abi.encodePacked(result, extraByte);
        } else if (isNegative) {
            result[result.length - 1] |= 0x80;
        }

        return result;
    }
}
