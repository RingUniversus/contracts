// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibUtil {
    function sqrt(uint256 x) public pure returns (uint256 y) {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function sqr(uint256 a) public pure returns (uint256) {
        return a * a;
    }

    function caculateDistance(uint256 distanceX, uint256 distanceY)
        public
        pure
        returns (uint256)
    {
        return sqrt(sqr(distanceX) + sqr(distanceY));
    }
}
