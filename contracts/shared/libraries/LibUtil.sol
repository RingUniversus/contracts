// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibUtil {
    function sqrt(int256 x) public pure returns (int256 y) {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

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

    function sqr(int256 a) public pure returns (int256) {
        return a * a;
    }

    function sqr(uint256 a) public pure returns (uint256) {
        return a * a;
    }

    function caculateDistance(
        int256 distanceX,
        int256 distanceY
    ) public pure returns (int256) {
        return sqrt(sqr(distanceX) + sqr(distanceY));
    }

    function caculateDistance(
        uint256 distanceX,
        uint256 distanceY
    ) public pure returns (uint256) {
        return sqrt(sqr(distanceX) + sqr(distanceY));
    }

    function distanceSpendTime(
        uint256 distance,
        uint256 speedCoefficient
    ) public pure returns (uint256) {
        return distance / speedCoefficient;
    }
}
