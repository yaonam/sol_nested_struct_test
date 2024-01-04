// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

struct Execution {
    address target;
    uint256 value;
    bytes data;
}

struct NestedExecution {
    Execution execution;
    bool other;
}

struct ModifiedExecution {
    address target;
    uint256 value;
    bytes data;
    bool other;
}

contract Callee {
    function foo() external payable {}
}

contract StructUser {
    function nestedExecBatch(NestedExecution[] calldata execs) external {
        for (uint i; i < execs.length; ++i) {
            Execution calldata exec = execs[i].execution;
            (bool success, ) = exec.target.call{value: exec.value}(exec.data);
            require(success || execs[i].other);
        }
    }

    function modifiedExecBatch(ModifiedExecution[] calldata execs) external {
        for (uint i; i < execs.length; ++i) {
            ModifiedExecution calldata exec = execs[i];
            (bool success, ) = exec.target.call{value: exec.value}(exec.data);
            require(success || exec.other);
        }
    }
}

contract CounterTest is Test {
    Callee public callee;
    StructUser public structUser;

    function setUp() public {
        callee = new Callee();
        structUser = new StructUser();
    }

    function nestedX(uint x) public {
        NestedExecution[] memory execs = new NestedExecution[](x);
        for (uint i; i < x; ++i) {
            execs[i].execution = Execution(
                address(callee),
                0,
                abi.encodeWithSelector(callee.foo.selector)
            );
        }
        structUser.nestedExecBatch(execs);
    }

    function test_Nested1() public {
        nestedX(1);
    }

    function test_Nested5() public {
        nestedX(5);
    }

    function test_Nested10() public {
        nestedX(10);
    }

    function modifiedX(uint x) public {
        ModifiedExecution[] memory execs = new ModifiedExecution[](x);
        for (uint i; i < x; ++i) {
            execs[i].target = address(callee);
            execs[i].value = 0;
            execs[i].data = abi.encodeWithSelector(callee.foo.selector);
        }
        structUser.modifiedExecBatch(execs);
    }

    function test_Modified1() public {
        modifiedX(1);
    }

    function test_Modified5() public {
        modifiedX(5);
    }

    function test_Modified10() public {
        modifiedX(10);
    }
}
