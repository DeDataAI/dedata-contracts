// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Nonces.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PointHelper is Initializable, Nonces, OwnableUpgradeable {
  struct UserPoint {
    uint256 points;
    uint256 tasks;
  }

  struct Point {
    uint256 nonce;
    uint256 points;
    uint256 tasks;
  }

  // @notice records the points of the user
  // @dev destination address => UserPoint
  mapping(address => UserPoint) public userPoints;

  // @notice address of the oracle
  address public oracle;

  // -------- Events --------
  // @dev event of adding points
  event PointsAdded(
    address indexed user,
    uint256 nonce,
    uint256 points,
    uint256 tasks
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev initialize the contract
   * @param _owner - Address of the owner
   * @param _oracle - Address of the oracle
   */
  function initialize(address _owner, address _oracle) public initializer {
    __Ownable_init(_owner);
    oracle = _oracle;
  }

  /**
   * @notice add points to the user
   * @param user - Address of the user
   * @param point - Point struct
   * @param oracleSignature - Signature of the oracle
   */
  function addPoints(
    address user,
    Point calldata point,
    bytes calldata oracleSignature
  ) external {
    bytes32 messageHash = getMessageHash(user, point);
    require(
      ECDSA.recover(messageHash, oracleSignature) == oracle,
      "Invalid oracle signature"
    );

    _useCheckedNonce(user, point.nonce);

    userPoints[user].points += point.points;
    userPoints[user].tasks += point.tasks;

    emit PointsAdded(user, point.nonce, point.points, point.tasks);
  }

  /**
   * @notice get the message hash
   * @param user - Address of the user
   * @param point - Point struct
   */
  function getMessageHash(
    address user,
    Point calldata point
  ) public pure returns (bytes32) {
    return
      keccak256(abi.encode(user, point.nonce, point.points, point.tasks));
  }

  /**
   * @dev set the oracle address
   * @param _oracle - Address of the oracle
   */
  function setOracle(address _oracle) external onlyOwner {
    require(_oracle != address(0), "Invalid oracle address");
    require(_oracle != oracle, "Same oracle address");
    oracle = _oracle;
  }
}
