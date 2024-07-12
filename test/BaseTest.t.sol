// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.22;

// External
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Tapioca
import {TapToken, ITapToken} from "contracts/tokens/TapToken.sol";
import {TwTAP, TWAMLPool, TWAML} from "contracts/twTAP2.sol";
import {MockPearlmit} from "contracts/mocks/MockPearlmit.sol";
import {MockCluster} from "contracts/mocks/MockCluster.sol";
import {IPearlmit} from "contracts/interfaces/IPearlmit.sol";
import {ICluster} from "contracts/interfaces/ICluster.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {StringUtilsLib} from "string-utils-lib/StringUtilsLib.sol";

// TODO Split into multiple part?
contract TapTokenTest is Test, TWAML {
    using StringUtilsLib for string;

    uint32 aEid = 1;
    uint256 baseTime;

    TapToken tapToken;

    address public userA = address(1001);
    uint256 public initialBalance = 100 ether;
    uint256 EPOCH_DURATION = 1 weeks;
    uint256 OPERATIONS_LIMIT = 1000;

    /**
     * DEPLOY setup addresses
     */
    TwTAP twTap;
    address __endpoint;
    address __contributors = address(0x30);
    address __earlySupporters = address(0x31);
    address __supporters = address(0x32);
    address __lbp = address(0x33);
    address __dao = address(0x34);
    address __airdrop = address(0x35);
    uint256 __governanceEid = 1;
    address __owner = address(this);

    // Mocks
    address __mockendpoint = address(0x36);
    address __mockTapTokenSender = address(0x37);
    address __mockTapTokenReceiver = address(0x38);
    address __mockExtExec = address(0x39);
    MockPearlmit pearlmit;
    MockCluster cluster;

    /**
     * @dev Setup the OApps by deploying them and setting up the endpoints.
     */
    function setUp() public {
        vm.deal(userA, 1000 ether);
        vm.label(userA, "userA");

        pearlmit = new MockPearlmit("Pearlmit", "1", address(this), 0);
        cluster = new MockCluster(aEid, __owner);

        tapToken = new TapToken(
            ITapToken.TapTokenConstructorData(
                EPOCH_DURATION,
                address(__mockendpoint),
                __contributors,
                __earlySupporters,
                __supporters,
                __lbp,
                __dao,
                __airdrop,
                __governanceEid,
                address(this),
                __mockTapTokenSender,
                __mockTapTokenReceiver,
                __mockExtExec,
                IPearlmit(address(pearlmit)),
                ICluster(address(cluster))
            )
        );
        vm.label(address(tapToken), "TAP_TOKEN");

        twTap = new TwTAP(payable(address(tapToken)), IPearlmit(address(pearlmit)), address(this));
        baseTime = block.timestamp;
        twTap.setCluster(ICluster(address(cluster)));
        vm.label(address(twTap), "twTAP");

        vm.prank(userA);
        tapToken.approve(address(pearlmit), type(uint256).max);

        // Create and distribute a reward token?
    }

    // function testInitial() external {
    //     console.log("----Initial----");
    //     _printTWAMLParams();

    //     deal(address(tapToken), userA, 1e6 ether);

    //     vm.prank(userA);
    //     twTap.participate(userA, 2000 ether, 21 days);

    //     console.log("----1 participant----");
    //     _printTWAMLParams();
    //     _printTWAMLParams_CSV(string(""));
    // }

    struct DataDump {
        uint256 timestamp;
        uint256 totalParticipants;
        uint256 averageMagnitude;
        uint256 totalDeposited;
        uint256 cumulative;
    }

    function testExecute() external {
        uint256 case_num = 3;
        uint256 version_num = 1;
        string memory ifname = string(abi.encodePacked("./results/inputfiles/test", vm.toString(case_num), ".csv"));
        string memory ofname = string(
            abi.encodePacked("./results/outputs/out", vm.toString(case_num), "_v", vm.toString(version_num), ".csv")
        );
        string memory line;
        uint256 count;

        DataDump[] memory dump = new DataDump[](OPERATIONS_LIMIT);

        for (;;) {
            line = vm.readLine(ifname);
            if (bytes(line).length == 0) {
                break;
            }
            // console.log(line);
            count++;
            (uint256 timestamp, uint256 operation, address user, uint256 amount, uint256 duration) = _processLine(line);
            _executeOp(timestamp, operation, user, amount, duration, count);
            (uint256 totalParticipants, uint256 averageMagnitude, uint256 totalDeposited, uint256 cumulative) =
                _getTWAMLParams();
            dump[count - 1] = DataDump(timestamp, totalParticipants, averageMagnitude, totalDeposited, cumulative);
        }

        _dumpToFile(ofname, count, dump);
    }

    function testMaxGrowth() external {
        uint256 case_num = 1;
        uint256 version_num = 2;
        string memory ifname =
            string(abi.encodePacked("./results/inputfiles/testMaximal", vm.toString(case_num), ".csv"));
        string memory ofnameTWAML = string(
            abi.encodePacked(
                "./results/outputs/out_maxGrowthTWAML", vm.toString(case_num), "_v", vm.toString(version_num), ".csv"
            )
        );
        string memory ofnameDeposits = string(
            abi.encodePacked(
                "./results/outputs/out_maxGrowthDeposits", vm.toString(case_num), "_v", vm.toString(version_num), ".csv"
            )
        );

        string memory line = vm.readLine(ifname);
        if (bytes(line).length == 0) {
            return;
        }

        (uint256 timeskip, uint256 iterations, address user, uint256 initAmount,) = _processLine(line);
        DataDump[] memory dump = new DataDump[](iterations);
        DataDump[] memory dumpDeposits = new DataDump[](iterations);
        uint256[] memory expirations = new uint256[](iterations);
        uint256 expirycounter = 0;
        timeskip = timeskip - baseTime;

        for (uint256 i = 0; i < iterations; i++) {
            uint256 timestamp = baseTime + i * timeskip;
            uint256 amount;
            uint256 duration;

            {
                (,, uint256 totalDeposited, uint256 cumulative) = _getTWAMLParams();

                (bool success, bytes memory data) =
                    address(twTap).call(abi.encodeWithSignature("lastEpochCumulative()"));

                if (success) {
                    cumulative = abi.decode(data, (uint256));
                    if (cumulative == 0) {
                        cumulative = EPOCH_DURATION;
                    }
                }

                // Find minimum voting amount
                amount = computeMinWeight(totalDeposited + twTap.VIRTUAL_TOTAL_AMOUNT(), twTap.MIN_WEIGHT_FACTOR());
                if (initAmount > 0 && i == 0) amount = initAmount;
                if (amount > 1e25) amount = 1e25;

                // Get max duration
                uint256 maxMagnitude = cumulative * 4 - 1;
                uint256 MCsum = maxMagnitude + cumulative;
                duration = sqrt(MCsum * MCsum - cumulative * cumulative) / EPOCH_DURATION * EPOCH_DURATION;
                if (duration > twTap.MAX_LOCK_DURATION()) {
                    duration = twTap.MAX_LOCK_DURATION() / EPOCH_DURATION * EPOCH_DURATION;
                }
            }

            // Check expiry
            while (timestamp > expirations[expirycounter] && i > 0 && expirycounter < i) {
                _executeOp(timestamp, 2, address(uint160(expirycounter + 1)), 0, 0, i);
                expirycounter++;
            }

            {
                string memory log = string(
                    abi.encodePacked(
                        "It:",
                        vm.toString(i),
                        ", tstamp:",
                        vm.toString(timestamp),
                        ", amt:",
                        vm.toString(amount / 1e18),
                        " ETH TAP for weeks:",
                        vm.toString(duration / EPOCH_DURATION)
                    )
                );
                console.log(log);
            }

            uint256 tokenId = _executeOp(timestamp, 1, user, amount, duration, i);
            (, bool voting,,,, uint256 expiry,,,,) = twTap.participants(tokenId);
            expirations[tokenId - 1] = expiry;
            (uint256 totalParticipants, uint256 averageMagnitude, uint256 totalDeposited, uint256 cumulative) =
                _getTWAMLParams();
            dump[i] = DataDump(timestamp, totalParticipants, averageMagnitude, totalDeposited, cumulative);
            dumpDeposits[i] = DataDump(timestamp, voting ? 1 : 0, 0, amount / 1e18, duration / EPOCH_DURATION);
        }
        _dumpToFile(ofnameTWAML, iterations, dump);
        _dumpToFile(ofnameDeposits, iterations, dumpDeposits);
    }

    function _dumpToFile(string memory fname, uint256 count, DataDump[] memory dump) internal {
        string memory output;

        for (uint256 i = 0; i < count; i++) {
            string memory line = string(
                abi.encodePacked(
                    vm.toString(dump[i].timestamp),
                    ",",
                    vm.toString(dump[i].totalParticipants),
                    ",",
                    vm.toString(dump[i].averageMagnitude),
                    ",",
                    vm.toString(dump[i].totalDeposited),
                    ",",
                    vm.toString(dump[i].cumulative)
                )
            );
            output = string.concat(output, line, "\n");
        }
        vm.writeFile(fname, output);
    }

    function _executeOp(
        uint256 timestamp,
        uint256 operation,
        address user,
        uint256 amount,
        uint256 duration,
        uint256 count
    ) internal returns (uint256 tokenId) {
        vm.warp(timestamp);

        // pre-checks
        // week check
        uint256 weekDiff = twTap.currentWeek() - twTap.lastProcessedWeek();
        if (weekDiff != 0) {
            twTap.advanceWeek(weekDiff);
            console.log("Adavnced by", weekDiff, "weeks");
        }

        if (operation == 1) {
            deal(address(tapToken), user, amount);
            vm.startPrank(user);
            tapToken.approve(address(pearlmit), type(uint256).max);
            tokenId = twTap.participate(user, amount, duration);
            vm.stopPrank();
            console.log("Line ", count, "processed. Participated Id: ", tokenId);
        } else if (operation == 2) {
            twTap.exitPosition(uint160(user));
            console.log("Line ", count, "processed. Exited: ", uint160(user));
        }
    }

    function _getTWAMLParams()
        internal
        view
        returns (uint256 totalParticipants, uint256 averageMagnitude, uint256 totalDeposited, uint256 cumulative)
    {
        (totalParticipants, averageMagnitude, totalDeposited, cumulative) = twTap.twAML();
    }

    function _printTWAMLParams() internal view {
        (uint256 totalParticipants, uint256 averageMagnitude, uint256 totalDeposited, uint256 cumulative) =
            _getTWAMLParams();
        console.log("totalParticipants: ", totalParticipants);
        console.log("averageMagnitude: ", averageMagnitude);
        console.log("totalDeposited: ", totalDeposited);
        console.log("cumulative: ", cumulative);
    }

    function _printTWAMLParams_CSV(string memory fname) internal view {
        (uint256 totalParticipants, uint256 averageMagnitude, uint256 totalDeposited, uint256 cumulative) =
            _getTWAMLParams();
        string memory line = string(
            abi.encodePacked(
                vm.toString(block.timestamp),
                ",",
                vm.toString(totalParticipants),
                ",",
                vm.toString(averageMagnitude),
                ",",
                vm.toString(totalDeposited),
                ",",
                vm.toString(cumulative)
            )
        );
        console.log(line);
    }

    function _processLine(string memory line)
        internal
        returns (uint256 timestamp, uint256 operation, address user, uint256 amount, uint256 duration)
    {
        string[] memory newtext = line.split(",", 10);

        timestamp = newtext[0].parseInt() + baseTime;
        operation = newtext[1].parseInt();
        user = address(uint160(newtext[2].parseInt()));
        amount = newtext[3].parseInt() * 1e18;
        duration = newtext[4].parseInt() * EPOCH_DURATION;
    }
}
