// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Nonces.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PointHelper is Initializable, Nonces, OwnableUpgradeable {
  using SafeERC20 for IERC20;

  struct UserPoint {
    uint256 points;
    uint256 tasks;
  }

  struct Point {
    uint256 nonce;
    uint256 points;
    uint256 tasks;
  }

  struct Bonus {
    uint256 nonce;
    address token;
    uint256 amount;
  }

  // @notice records the points of the user
  // @dev destination address => UserPoint
  mapping(address => UserPoint) public userPoints;

  // @notice address of the oracle
  address public oracle;

  // @notice dedata governance token address
  IERC20 public token;

  // @notice exchanged points
  // @dev destination address => points
  mapping(address => uint256) public exchangedPoints;

  // @notice exchange rate: 1 point = exchangeRate tokens, 1e5 = 100%
  uint256 public exchangeRate;

  // @notice records the bonus of the user
  // @dev user address => token address => bonus
  mapping(address => mapping(address => uint256)) public userBonuses;

  // @notice bonus nonces
  mapping(address account => uint256) public bonusNonces;

  // -------- Events --------
  // @dev event of adding points
  event PointsAdded(
    address indexed user,
    uint256 nonce,
    uint256 points,
    uint256 tasks
  );
  // @dev event of token claimed
  event Claimed(address indexed user, uint256 points, uint256 amount);
  // @dev event of bonus claimed
  event BonusClaimed(
    address indexed user,
    uint256 nonce,
    address token,
    uint256 amount
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev initialize the contract
   * @param _owner - Address of the owner
   * @param _oracle - Address of the oracle
   * @param _token - Address of the token
   * @param _exchangeRate - Exchange rate
   */
  function initialize(
    address _owner,
    address _oracle,
    address _token,
    uint256 _exchangeRate
  ) public initializer {
    __Ownable_init(_owner);
    oracle = _oracle;
    token = IERC20(_token);
    exchangeRate = _exchangeRate;
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
    return keccak256(abi.encode(user, point.nonce, point.points, point.tasks));
  }

  /**
   * @dev claim tokens
   */
  function claim() external {
    require(
      userPoints[msg.sender].points > exchangedPoints[msg.sender],
      "Insufficient points"
    );

    uint256 points = userPoints[msg.sender].points -
      exchangedPoints[msg.sender];
    exchangedPoints[msg.sender] += points;

    uint256 tokens = (points * exchangeRate) / 1e5;
    IERC20(token).safeTransfer(msg.sender, tokens);

    emit Claimed(msg.sender, points, tokens);
  }

  /**
   * @notice claim bonus
   * @param user - Address of the user
   * @param bonus - Bonus struct
   * @param oracleSignature - Signature of the oracle
   */
  function claimBonus(
    address user,
    Bonus calldata bonus,
    bytes calldata oracleSignature
  ) external {
    bytes32 messageHash = getBonusMessageHash(user, bonus);
    require(
      ECDSA.recover(messageHash, oracleSignature) == oracle,
      "Invalid oracle signature"
    );

    // It is important to do x++ and not ++x here.
    uint256 current = bonusNonces[user]++;
    require(current == bonus.nonce, "Invalid bonus nonce");

    userBonuses[user][bonus.token] += bonus.amount;

    IERC20(bonus.token).safeTransfer(user, bonus.amount);

    emit BonusClaimed(user, bonus.nonce, bonus.token, bonus.amount);
  }

  /**
   * @notice get bonus message hash
   * @param user - Address of the user
   * @param bonus - Bonus struct
   */
  function getBonusMessageHash(
    address user,
    Bonus calldata bonus
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(user, bonus.nonce, bonus.token, bonus.amount));
  }

  /**
   * @dev withdraw token
   * @param _token - Address of the token
   * @param _amount - Amount of token
   */
  function withdraw(address _token, uint256 _amount) external onlyOwner {
    IERC20(_token).safeTransfer(msg.sender, _amount);
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

  /**
   * @dev set the token address
   * @param _token - Address of the token
   */
  function setToken(address _token) external onlyOwner {
    require(_token != address(0), "Invalid token address");
    require(_token != address(token), "Same token address");
    token = IERC20(_token);
  }

  /**
   * @dev set the exchange rate
   * @param _exchangeRate - Exchange rate
   */
  function setExchangeRate(uint256 _exchangeRate) external onlyOwner {
    require(_exchangeRate > 0, "Invalid exchange rate");
    require(_exchangeRate != exchangeRate, "Same exchange rate");
    exchangeRate = _exchangeRate;
  }
}
