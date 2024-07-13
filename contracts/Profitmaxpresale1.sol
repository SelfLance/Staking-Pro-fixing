// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Profitmaxpresale1 is ReentrancyGuard {
    address public admin;
    ERC20 public token;

    uint256 public constant MIN_STAKING_AMOUNT = 25 ether;
    uint256 public multiplier = 10 ** 18;

    uint256 public constant STAKING_DURATION = 1 minutes; //60 minutes; //60 minutes; :todo need to change

    uint256 public constant MAX_WITHDRAWAL_MULTIPLIER = 3;
    uint256 public constant REWARD_PERCENTAGE_PER_SECOND = 5e15; // 0.5% in 18 decimals
    uint256 public constant WITHDRAWAL_FEE_PERCENTAGE = 10; // 10% withdrawal fee
    uint256 public constant DIRECT_SPONSOR_INCOME_PERCENTAGE = 5;

    uint256 public constant WEEKLY_SALARY_PERIOD = 1 weeks; // Weekly salary distribution period
    mapping(uint256 => address[]) public levelUsersArray;
    uint256 public lastWeeklyRewardsDistribution;
    mapping(address => mapping(uint256 => uint256)) public rankAmountWithdrawn; // Separate mapping for each rank
    mapping(address => mapping(uint256 => uint256)) public rankAchievedTime; // Time when user achieved each rank

    uint256 public constant SECONDS_PER_WEEK = 604800; // 7 days in seconds
    mapping(address => uint256) public totalRewardWithdraw;

    struct UserStaking {
        uint256 stakedAmount;
        uint256 stakingEndTime;
        uint256 startDate;
        uint256 totalWithdrawn;
        uint256 lastClaimTime;
    }
    struct UserStakes {
        uint256 stakedAmount;
        uint256 stakesTime;
        address referrer;
    }

    struct Rewards {
        uint256 totalRewards;
        uint256 dailyRewards;
        uint256 lastClaimTime;
    }

    struct User_children {
        address[] child;
    }

    struct LeadershipRewards {
        uint256 star;
        uint256 teamCount;
        uint256 reward;
        uint256 totalRewardReceived;
        uint256 starReceived;
    }

    mapping(address => UserStaking[]) public userStaking;
    mapping(address => uint) public totalInvestedAmount;
    mapping(address => uint) public levelIncomeAmountClaimed;
    mapping(address => uint) public levelIncomePreviousStage;
    mapping(address => Rewards) public userRewards;
    mapping(address => Rewards) public userReferralRewards;
    mapping(address => address) public parent;
    mapping(address => User_children) private referrerToDirectChildren;
    mapping(address => User_children) private referrerToIndirectChildren;
    mapping(uint => mapping(address => address[])) public levelUsers;
    mapping(uint => mapping(address => uint256)) public levelCountUsers;
    mapping(address => uint256) public maxTierReferralCounts;
    mapping(address => mapping(address => bool)) public rewardAmount;
    mapping(address => bool) public userValidation;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist;
    mapping(address => mapping(uint256 => LeadershipRewards))
        public teamBonuses;
    // mapping(uint256 => LeadershipReward) public leadershipRewards;
    mapping(address => UserStakes[]) userStakes; // This is for Stackes Push to get list of all stakes with detail

    // Assume a structure for user data that includes referrals and levels unlocked
    struct User {
        uint256 stakedTokens;
        address referrer;
        uint256 directReferrals;
        uint256[] levelIncomes;
        uint256[] lastStakeUpdate;
        uint256 stakeTimestamp;
        uint256 lastUpdate;
        uint256 level;
        uint256 leafNo;
        uint256[] levelIncomeReceived;
        uint256 rewardPerMinute;
    }

    mapping(address => User) public users;
    uint256[] public levelPercentages = [
        250,
        100,
        75,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        25,
        25,
        25,
        25,
        25,
        10,
        10,
        10,
        10,
        10
    ]; // 20 levels

    // Mapping to track last salary distribution time for each user
    mapping(address => uint256) public lastSalaryDistributionTime;
    event SalaryIncomeClaimed(address indexed user, uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 endTime);
    event RewardsClaimed(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount, uint256 fees);
    event WithdrawTeamBonus(address indexed userr, uint256 rankReward);

    LeadershipRewards[] public leadershipRewards;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier notBlacklisted(address _user) {
        require(!blacklist[_user], "User is blacklisted");
        _;
    }

    modifier whitelisted(address _user) {
        require(whitelist[_user], "User is not whitelisted");
        _;
    }

    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress);
        admin = msg.sender;
    }

    function stakeTokens(
        uint256 tokenAmount,
        address referrer
    ) public nonReentrant notBlacklisted(msg.sender) {
        // uint256 stakedAmount = tokenAmount * (10 ** token.decimals());
        require(
            tokenAmount >= MIN_STAKING_AMOUNT,
            "Amount needs to be at least 25 USDT"
        );
        require(msg.sender != admin, "Admin cannot stake");
        // Convert token amount to equivalent wei
        if (parent[msg.sender] == address(0) && msg.sender != referrer) {
            parent[msg.sender] = referrer;
            setLevelUsers(msg.sender, referrer);
        }
        uint256 stakingEndTime = block.timestamp + STAKING_DURATION;
        uint256 startDate = block.timestamp;
        UserStaking memory newStake = UserStaking({
            stakedAmount: tokenAmount,
            stakingEndTime: stakingEndTime,
            startDate: startDate,
            totalWithdrawn: 0,
            lastClaimTime: block.timestamp
        });

        userStaking[msg.sender].push(newStake);

        totalInvestedAmount[msg.sender] += tokenAmount;

        // Update referral rewards for the referrer
        updateReferralRewards(msg.sender, tokenAmount);

        // Calculate daily rewards based on staked amount and update user's daily rewards
        uint256 dailyRewards = calculateRewardPerMinute(tokenAmount);
        userRewards[msg.sender].dailyRewards += dailyRewards;

        // Calculate and add leadership rewards
        uint256 earnedLeadershipRewards = calculateLeadershipRewards(
            msg.sender
        );
        userRewards[msg.sender].totalRewards += earnedLeadershipRewards;

        token.transferFrom(msg.sender, address(this), tokenAmount);
        // Create a new UserStakes instance
        userStakes[msg.sender].push(
            UserStakes({
                stakedAmount: tokenAmount,
                stakesTime: block.timestamp,
                referrer: referrer
            })
        );
        if (referrer != address(0) && referrer != msg.sender)
            updateLevelIncome(msg.sender, tokenAmount, referrer);
        // User storage user = users[msg.sender];

        // user.stakedTokens += tokenAmount;
        // user.stakeTimestamp = block.timestamp;
        // user.lastUpdate = block.timestamp;

        // if (user.referrer == address(0) && referrer != msg.sender) {
        //     user.referrer = referrer;
        //     users[referrer].directReferrals += 1;
        // }

        // updateLevelIncome(msg.sender);
    }

    function updateLevelIncome(address _user) public view returns (uint256) {
        User memory user = users[_user];
        uint256 totalReward;
        uint256 i = 1;
        for (i = 1; i < user.level; i++) {}
        uint256 stakesTime = (block.timestamp - user.lastStakeUpdate[i - 1]) /
            60; // Per Minute
        if (stakesTime > 0) {
            uint256 rewardPerMinute = user.levelIncomes[i - 1];
            totalReward += (rewardPerMinute * stakesTime);
        }
        totalReward += user.levelIncomeReceived[i - 1];
        return totalReward;
    }

    function updateLevelIncome(
        address sender,
        uint256 tokenAmount,
        address referrer
    ) internal {
        User storage user = users[referrer];
        users[sender].leafNo = user.leafNo + 1;
        if (user.level < 20) user.level++;
        uint256 rewardPerMinute = calculateRewardPerMinute(tokenAmount) / 60;
        for (uint i = user.leafNo; i > 0; i--) {
            // uint256 reward = rewardPerMinute
            User storage user1 = users[user.referrer];
            uint256 level = user1.level;
            uint256 lastUpdates = user1.lastUpdate;
            if (user1.rewardPerMinute > 0) {
                uint256 timeToMins = (block.timestamp - lastUpdates) / 60;
                if (timeToMins > 0)
                    user1.levelIncomeReceived[i - 1] +=
                        timeToMins *
                        user1.rewardPerMinute;
            }
            user1.lastUpdate = block.timestamp;

            uint256 reward = (rewardPerMinute * levelPercentages[level - 1]) /
                1000;
            users[user.referrer].levelIncomes[i] += reward;
            users[user.referrer].lastStakeUpdate[i] = block.timestamp;
            // users[user.referrer].rewardPerMinute += reward;

            user = users[user.referrer];
        }
    }

    function calculateRewardPerMinute(
        uint256 stakedAmount
    ) internal pure returns (uint256) {
        uint256 tokens = stakedAmount / (10 ** 18); // Convert stakedAmount from wei to tokens
        // Calculate rewards based on token amount
        if (tokens == 50000) {
            return 1000 * 10 ** 18; // 1000 tokens per minute (2%)
        } else if (tokens == 10000) {
            return 175 * 10 ** 18; // 175 tokens per minute (1.75%)
        } else if (tokens == 5000) {
            return 75 * 10 ** 18; // 75 tokens per minute (1.5%)
        } else if (tokens == 1000) {
            return 125 * 10 ** 17; // 12.5 tokens per minute (1.25%)
        } else if (tokens == 500) {
            return 5 * 10 ** 18; // 5 tokens per minute (1%)
        } else if (tokens == 100) {
            return 75 * 10 ** 16; // 75 tokens per minute (0.75%)
        } else if (tokens == 25) {
            return 125 * 10 ** 15; // 5 tokens per minute (0.5%)
        } else {
            return 0; // No rewards for amounts less than 50 tokens
        }
    }

    function rewardsPerMinute(address user) external view returns (uint256) {
        // Retrieve the staked amount of the user
        uint256 stakedAmount = totalInvestedAmount[user];

        // Calculate rewards per minute based on the staked amount
        return calculateRewardPerMinute(stakedAmount);
    }

    function calculateLeadershipRewards(
        address user
    ) internal view returns (uint256) {
        uint256 totalTeamCount = levelCountUsers[7][user];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < leadershipRewards.length; i++) {
            if (totalTeamCount >= leadershipRewards[i].teamCount) {
                totalRewards += leadershipRewards[i].reward;
            }
        }

        return totalRewards;
    }

    function updateReferralRewards(
        address user,
        uint256 stakedAmount
    ) internal {
        address currentReferrer = parent[user];

        // Check if the referrer exists and has at least three direct children
        if (
            currentReferrer != address(0) &&
            levelCountUsers[1][currentReferrer] >= 3
        ) {
            // Get the direct children of the current referrer
            address[] memory directChildren = levelUsers[1][currentReferrer];

            // Check if the new direct child is not one of the first two directs
            if (
                directChildren.length > 2 &&
                !rewardAmount[user][currentReferrer]
            ) {
                // Update the referral rewards for the referrer
                uint256 referralAmount = (stakedAmount *
                    DIRECT_SPONSOR_INCOME_PERCENTAGE) / 100;
                userReferralRewards[currentReferrer]
                    .totalRewards += referralAmount;
                userReferralRewards[currentReferrer].lastClaimTime = block
                    .timestamp;

                // Mark that the new direct child has received the reward from this referrer
                rewardAmount[user][currentReferrer] = true;
            }
        }
    }

    function updateRewards(address user) internal {
        UserStaking[] storage stakes = userStaking[user];
        Rewards storage rewards = userRewards[user];
        uint256 totalRewards = rewards.totalRewards; // Initialize totalRewards to current total rewards
        for (uint256 i = 0; i < stakes.length; i++) {
            UserStaking storage stake = stakes[i]; // Define storage reference to the current stake
            // Calculate rewards per minute based on staked amount
            uint256 rewardPerMinute = calculateRewardPerMinute(
                stake.stakedAmount
            ); //(60 minutes); // Convert it if you change 60 Minutes to 1 minutes accordingly
            // Calculate total rewards since last claim
            uint256 minutesSinceLastClaim = (block.timestamp -
                stake.lastClaimTime) / 60; // Change according to your time
            uint256 rewardsSinceLastClaim = rewardPerMinute *
                minutesSinceLastClaim;
            // Update last claim time
            stake.lastClaimTime = block.timestamp;
            // Add rewards since last claim to total rewards
            totalRewards += rewardsSinceLastClaim;
        }
        // Calculate leadership rewards and add to total rewards
        uint256 earnedLeadershipRewards = calculateLeadershipRewards(user);
        userRewards[user].totalRewards += earnedLeadershipRewards;
        totalRewards += earnedLeadershipRewards;
        // Update total rewards
        rewards.totalRewards = totalRewards;
    }

    function checkRewards(
        address user
    )
        public
        view
        returns (
            uint256 totalRewards,
            uint256 remainingRewards,
            uint256 currentRewards,
            uint256 previousRewards
        )
    {
        UserStaking[] storage stakes = userStaking[user];
        uint256 blockTimestamp = block.timestamp;
        // Iterate through all stakes made by the user
        for (uint256 i = 0; i < stakes.length; i++) {
            UserStaking storage stake = stakes[i];
            // Calculate rewards only for active stakes or stakes with remaining rewards
            if (
                blockTimestamp < stake.stakingEndTime ||
                stake.totalWithdrawn < stake.stakedAmount
            ) {
                // Calculate the time difference since the last claim
                uint256 minutesSinceLastClaim = (blockTimestamp -
                    stake.lastClaimTime) / 60; // 60; //60;
                // Ensure that there is a positive time difference
                if (minutesSinceLastClaim > 0) {
                    // Calculate rewards per minute based on staked amount
                    uint256 rewardPerMinute = calculateRewardPerMinute(
                        stake.stakedAmount
                    );
                    // Calculate rewards since last claim
                    uint256 rewardsSinceLastClaim = rewardPerMinute *
                        minutesSinceLastClaim;
                    // Accumulate total rewards
                    totalRewards += rewardsSinceLastClaim;
                    // Calculate remaining rewards
                    uint256 remainingRewardsForStake = stake.stakedAmount -
                        stake.totalWithdrawn;
                    remainingRewards += (remainingRewardsForStake >
                        rewardsSinceLastClaim)
                        ? rewardsSinceLastClaim
                        : remainingRewardsForStake;
                }
            }
        }
        // Calculate current rewards by subtracting remaining rewards from total rewards
        currentRewards = totalRewards - remainingRewards;
        // Calculate previous unclaimed rewards
        previousRewards = totalRewards - currentRewards;
        return (
            totalRewards,
            remainingRewards,
            currentRewards,
            previousRewards
        );
    }

    function withdraw(
        uint256 amountInEther
    ) public nonReentrant notBlacklisted(msg.sender) {
        require(amountInEther > 0, "Withdrawal amount must be greater than 0");
        // Convert ether amount to wei
        uint256 amountInWei = amountInEther * 1 ether;
        // Update rewards before calculating claimable rewards
        updateRewards(msg.sender);
        uint256 levelIncomeRewards = updateLevelIncome(msg.sender);

        if (levelIncomeRewards > 0) {
            userRewards[msg.sender].totalRewards += levelIncomeRewards;
            levelIncomeAmountClaimed[msg.sender] += levelIncomeRewards;
        }
        uint256 earnedLeadershipRewards = calculateLeadershipRewards(
            msg.sender
        );
        uint256 claimableRewards = earnedLeadershipRewards; // Initialize claimableRewards
        Rewards storage rewards = userRewards[msg.sender];
        claimableRewards += rewards.totalRewards; // Accumulate total rewards
        // Get the user's staked amount
        uint256 stakedAmount = totalInvestedAmount[msg.sender];
        // Calculate the maximum withdrawable amount (3x staked amount)
        uint256 maxWithdrawalAmount = stakedAmount * MAX_WITHDRAWAL_MULTIPLIER;
        // Ensure the requested withdrawal amount does not exceed the maximum withdrawable amount
        require(
            amountInWei <= maxWithdrawalAmount,
            "Requested withdrawal amount exceeds maximum withdrawable amount"
        );
        require(claimableRewards >= amountInWei, "Not enough rewards to claim");
        uint256 fee = (amountInWei * WITHDRAWAL_FEE_PERCENTAGE) / 100; // Calculate the fee (10% of the amount)
        token.transfer(msg.sender, amountInWei - fee);
        token.transfer(admin, fee);
        // Update total rewards after withdrawal
        totalRewardWithdraw[msg.sender] += amountInWei;
        userRewards[msg.sender].totalRewards -= amountInWei;
        emit RewardsClaimed(msg.sender, amountInWei);
    }

    function calculateRewards(
        address user,
        uint256 index
    ) internal view returns (uint256) {
        UserStaking storage staking = userStaking[user][index];
        uint256 totalRewards = userRewards[user].totalRewards;
        if (block.timestamp > staking.stakingEndTime) {
            uint256 stakingDuration = staking.stakingEndTime -
                staking.startDate;
            uint256 reward = (staking.stakedAmount *
                REWARD_PERCENTAGE_PER_SECOND *
                stakingDuration) / 1e18;
            totalRewards += reward;
        }
        return totalRewards;
    }

    function totalReferralRewards(address user) public view returns (uint256) {
        return userReferralRewards[user].totalRewards;
    }

    function setLevelUsers(address _user, address _referrer) internal {
        address currentReferrer = _referrer;
        if (!isUserInArray(_user, levelUsers[1][currentReferrer])) {
            levelUsers[1][currentReferrer].push(_user);
            levelCountUsers[1][currentReferrer]++;
            levelUsersArray[1].push(_user); // Add user to the array at level 1
            // Add user as a d1rect child to the referrer
            referrerToDirectChildren[currentReferrer].child.push(_user);
            // Add user as an indirect child to all upline referrers
            setIndirectUsersRecursive(_user, _referrer);
        }
        for (uint i = 1; i <= 7; i++) {
            if (currentReferrer == admin) {
                break;
            } else {
                currentReferrer = parent[currentReferrer];
            }
        }
    }

    // Function to check if a user is already in the array
    function isUserInArray(
        address _user,
        address[] memory _array
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _user) {
                return true;
            }
        }
        return false;
    }

    // function updateLevelIncome(address user) public view returns (uint256) {
    //     address[] memory currentReferrer = showAllDirectChild(user);
    //     uint256 totalAmount = 0;
    //     uint256 currentReferrerLength = 20;

    //     for (uint256 i = 0; i < currentReferrer.length; i++) {
    //         uint256 stakingOfReferrer = userStakes[currentReferrer[i]][0]
    //             .stakedAmount;
    //         uint256 secondsSinceLastClaim = (block.timestamp -
    //             userStaking[currentReferrer[i]][0].lastClaimTime) / 60; // Claim Reward per minutes;
    //         stakingOfReferrer = calculateRewardPerMinute(stakingOfReferrer);
    //         if (i == 0 && secondsSinceLastClaim > 0) {
    //             totalAmount =
    //                 ((stakingOfReferrer * 25) / 100) *
    //                 secondsSinceLastClaim;
    //         }
    //         if (i == 1 && secondsSinceLastClaim > 0) {
    //             totalAmount +=
    //                 ((stakingOfReferrer * 10) / 100) *
    //                 secondsSinceLastClaim;
    //         }
    //         if (i == 2 && secondsSinceLastClaim > 0) {
    //             totalAmount +=
    //                 ((stakingOfReferrer * 7) / 100) *
    //                 secondsSinceLastClaim;
    //         }
    //         if (i > 2 && i < 11 && secondsSinceLastClaim > 0) {
    //             totalAmount +=
    //                 ((stakingOfReferrer * 5) / 100) *
    //                 secondsSinceLastClaim;
    //         }
    //         if (i > 10 && i < 16 && secondsSinceLastClaim > 0) {
    //             totalAmount +=
    //                 ((stakingOfReferrer * 2) / 100) *
    //                 secondsSinceLastClaim;
    //         }
    //         if (i > 15 && i < 21 && secondsSinceLastClaim > 0) {
    //             totalAmount +=
    //                 ((stakingOfReferrer * 1) / 100) *
    //                 secondsSinceLastClaim;
    //         }
    //     }
    //     // totalRewards += totalAmount;
    //     return totalAmount;

    //     // uint256 stakedAmount = 0; // Initialize stakedAmount to zero
    //     // uint256 levelIncome;
    //     // uint256 totalReferals = currentReferrer.length;
    //     // if (totalReferals == 0) {
    //     //     return 0;
    //     // } else if (totalReferals >= 1) {
    //     //     if (totalReferals == 1) {
    //     //         levelIncome = 25; //(stakedAmount * 50) / 100; // 50% for 1st level
    //     //     } else if (totalReferals == 2) {
    //     //         levelIncome = 10; //(stakedAmount * 25) / 100; // 25% for 2nd level
    //     //     } else if (totalReferals == 3) {
    //     //         levelIncome = 7; //(stakedAmount * 10) / 100; // 10% for 3rd level
    //     //     } else if (totalReferals >= 4 && totalReferals <= 10) {
    //     //         levelIncome = 5; //(stakedAmount * 5) / 100; // 5% for 4th and 10th level
    //     //     } else if (totalReferals >= 11 && totalReferals <= 15) {
    //     //         levelIncome = 2; //(stakedAmount * 4) / 100; // 4% for 11th to 15th level
    //     //     } else if (totalReferals >= 16 && totalReferals <= 20) {
    //     //         levelIncome = 1; //(stakedAmount * 3) / 100; // 3% for 16th to 20th level
    //     //     }
    //     // }

    //     // uint256 blockTimestamp = block.timestamp;
    //     // uint256 totalRewards = 0;

    //     // for (uint i = 0; i < currentReferrer.length; i++) {
    //     //     address referaluser = currentReferrer[i];

    //     //     // Check if user has any staking history
    //     //     if (userStaking[referaluser].length > 0) {
    //     //         stakedAmount = userStaking[referaluser][
    //     //             userStaking[referaluser].length - 1
    //     //         ].stakedAmount; // Use last staking amount

    //     //         uint256 secondsSinceLastClaim = blockTimestamp -
    //     //             userStaking[referaluser][
    //     //                 userStaking[referaluser].length - 1
    //     //             ].lastClaimTime;
    //     //         if (secondsSinceLastClaim < 60) {
    //     //             //60
    //     //             //60
    //     //             break;
    //     //         }
    //     //         uint256 minutesSinceLastClaim = secondsSinceLastClaim / 60; //60; //60;

    //     //         // Calculate rewards per second
    //     //         uint256 rewardPerSecond = (stakedAmount *
    //     //             REWARD_PERCENTAGE_PER_SECOND) / 1e18;
    //     //         // Calculate total rewards since last claim
    //     //         uint256 rewardsSinceLastClaim = rewardPerSecond *
    //     //             minutesSinceLastClaim;
    //     //         // Ensure total rewards excluding rank rewards do not exceed 3x
    //     //         if (
    //     //             rewardsSinceLastClaim >
    //     //             3 *
    //     //                 userStaking[referaluser][
    //     //                     userStaking[referaluser].length - 1
    //     //                 ].stakedAmount
    //     //         ) {
    //     //             rewardsSinceLastClaim = (3 *
    //     //                 userStaking[referaluser][
    //     //                     userStaking[referaluser].length - 1
    //     //                 ].stakedAmount);
    //     //         }

    //     //         // Add rewards since last claim to total rewards
    //     //         totalRewards += rewardsSinceLastClaim;
    //     //     }
    //     // }

    //     // return ((((levelIncome * totalRewards) / 100) +
    //     //     levelIncomePreviousStage[msg.sender]) -
    //     //     levelIncomeAmountClaimed[msg.sender]);
    //     // // userRewards[user].totalRewards += (levelIncome * 50) / 100;
    // }
    function calculateHourlyReward(
        uint256 _amount,
        uint256 _hours
    ) internal pure returns (uint256) {
        // Implement your hourly reward calculation logic here
        return (_amount * _hours * 10) / 1000; // Example: 1% hourly reward
    }

    // function updateLevelIncome(address _user) internal returns (uint256) {
    //     User storage user = users[_user];

    //     // Calculate the elapsed time since the last update
    //     uint256 elapsedHours = (block.timestamp - user.lastUpdate) / 1 hours;
    //     if (elapsedHours == 0) return 0;

    //     // Calculate the hourly reward
    //     uint256 hourlyReward = calculateHourlyReward(
    //         user.stakedTokens,
    //         elapsedHours
    //     );

    //     // Update the last update timestamp
    //     user.lastUpdate = block.timestamp;

    //     uint256 remainingReward = hourlyReward;
    //     address currentReferrer = user.referrer;
    //     uint256 level = 1;
    //     uint256 reward;

    //     while (
    //         currentReferrer != address(0) && level <= 20 && remainingReward > 0
    //     ) {
    //         User storage referrer = users[currentReferrer];

    //         if (referrer.directReferrals >= level) {
    //             uint256 levelIncome = (hourlyReward *
    //                 levelPercentages[level - 1]) / 1000;
    //             referrer.levelIncomes.push(levelIncome);
    //             remainingReward -= levelIncome;
    //             reward += levelIncome;
    //         }

    //         currentReferrer = referrer.referrer;
    //         level++;
    //     }
    //     return reward;
    // }

    // function getLevelIncome(address _user) public view returns (uint256) {
    //     User storage user = users[_user];

    //     // Calculate the elapsed time since the last update
    //     uint256 elapsedHours = (block.timestamp - user.lastUpdate) / 1 hours;
    //     if (elapsedHours == 0) return 0;

    //     // Calculate the hourly reward
    //     uint256 hourlyReward = calculateHourlyReward(
    //         user.stakedTokens,
    //         elapsedHours
    //     );

    //     // Update the last update timestamp
    //     // user.lastUpdate = block.timestamp;

    //     uint256 remainingReward = hourlyReward;
    //     address currentReferrer = user.referrer;
    //     uint256 level = 1;
    //     uint256 reward;

    //     while (
    //         currentReferrer != address(0) && level <= 20 && remainingReward > 0
    //     ) {
    //         User storage referrer = users[currentReferrer];

    //         if (referrer.directReferrals >= level) {
    //             uint256 levelIncome = (hourlyReward *
    //                 levelPercentages[level - 1]) / 1000;
    //             referrer.levelIncomes.push(levelIncome);
    //             remainingReward -= levelIncome;
    //             reward += levelIncome;
    //         }

    //         currentReferrer = referrer.referrer;
    //         level++;
    //     }
    //     return reward;
    // }

    function setIndirectUsersRecursive(
        address _user,
        address _referrer
    ) internal {
        address presentReferrer = parent[_referrer];

        // Ensure that we have a valid referrer and avoid infinite loop
        while (presentReferrer != address(0)) {
            // Add the user as an indirect child of the current referrer
            referrerToIndirectChildren[presentReferrer].child.push(_user);

            // Move to the next level up in the referral hierarchy
            presentReferrer = parent[presentReferrer];
        }
    }

    function viewTeamLeadershipRewards(
        address user
    ) public view returns (uint256) {
        return calculateLeadershipRewards(user);
    }

    function showAllDirectChild(
        address user
    ) public view returns (address[] memory) {
        address[] memory children = referrerToDirectChildren[user].child;

        return children;
    }

    function showAllInDirectChild(
        address user
    ) public view returns (address[] memory) {
        address[] memory children = referrerToIndirectChildren[user].child;

        return children;
    }

    function totalRewardsReceived(
        address userAddress
    ) public view returns (uint256) {
        require(userAddress != address(0), "Invalid address");

        uint256 totalRewards = userReferralRewards[userAddress].totalRewards +
            userRewards[userAddress].totalRewards;

        return totalRewards;
    }

    function transferOwnership(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid new admin address");
        admin = newAdmin;
    }

    function addToBlacklist(address user) public onlyAdmin {
        blacklist[user] = true;
    }

    function removeFromBlacklist(address user) public onlyAdmin {
        blacklist[user] = false;
    }

    function addToWhitelist(address user) public onlyAdmin {
        whitelist[user] = true;
    }

    function removeFromWhitelist(address user) public onlyAdmin {
        whitelist[user] = false;
    }

    function getTotalRewardsPerSecond(
        address user
    ) public view returns (uint256) {
        uint256 totalRewards = userRewards[user].totalRewards;

        UserStaking[] storage stakes = userStaking[user];
        for (uint256 i = 0; i < stakes.length; i++) {
            if (block.timestamp > stakes[i].stakingEndTime) {
                stakes[i].stakingEndTime - stakes[i].startDate;
                uint256 secondsSinceLastClaim = stakes[i].lastClaimTime; // block.timestamp - stakes[i].lastClaimTime;

                // Calculate rewards per second and update total rewards
                uint256 rewardPerSecond = (stakes[i].stakedAmount *
                    REWARD_PERCENTAGE_PER_SECOND) / 1e18;
                uint256 totalReward = rewardPerSecond * secondsSinceLastClaim;

                totalRewards += totalReward;
            }
        }

        return totalRewards;
    }

    function calculateTotalTeamBusiness(
        address user
    ) internal view returns (uint256) {
        uint256 totalTeamBusiness = 0;
        address[] memory indirectChildren = showAllInDirectChild(user);

        // Calculate total team business (including indirect referrals)
        for (uint256 i = 0; i < indirectChildren.length; i++) {
            address child = indirectChildren[i];
            totalTeamBusiness += totalInvestedAmount[child];
        }

        return totalTeamBusiness;
    }

    function teamBonus(
        address user
    ) public view returns (uint256 rankReward, uint256 teamCount) {
        uint256 totalTeamCount = levelCountUsers[1][user]; // Retrieve direct team count
        // Add indirect referrals to the total team count
        address[] memory indirectChildren = showAllInDirectChild(user);
        for (uint256 i = 0; i < indirectChildren.length; i++) {
            totalTeamCount += levelCountUsers[1][indirectChildren[i]];
        }
        // Determine the rank reward based on the total team count
        if (totalTeamCount >= 5 && totalTeamCount < 25) {
            rankReward = 25; // Level 1 reward
        } else if (totalTeamCount >= 25 && totalTeamCount < 100) {
            rankReward = 100; // Level 2 reward
        } else if (totalTeamCount >= 100 && totalTeamCount < 500) {
            rankReward = 250; // Level 3 reward
        } else if (totalTeamCount >= 500 && totalTeamCount < 2500) {
            rankReward = 1250; // Level 4 reward
        } else if (totalTeamCount >= 2500 && totalTeamCount < 10000) {
            rankReward = 6250; // Level 5 reward
        } else if (totalTeamCount >= 10000 && totalTeamCount < 50000) {
            rankReward = 25000; // Level 6 reward
        } else if (totalTeamCount >= 50000) {
            rankReward = 62500; // Level 7 reward
        }

        return (rankReward, totalTeamCount);
    }

    function getTeamBonusData(
        address user,
        uint256 rank
    ) external view returns (uint256 rankReward, uint256 teamCount) {
        return (
            teamBonuses[user][rank].reward,
            teamBonuses[user][rank].teamCount
        );
    }

    function withdrawable(address user) public view returns (uint256) {
        uint256 totalRewards = userRewards[user].totalRewards; // Initialize totalRewards to current total rewards
        for (uint256 i = 0; i < userStaking[user].length; i++) {
            uint256 rewardPerMinute = calculateRewardPerMinute(
                userStaking[user][i].stakedAmount
            ) / 1 minutes; //(60 minutes); // Convert it if you change 60 Minutes to 1 minutes accordingly
            uint256 minutesSinceLastClaim = (block.timestamp -
                userStaking[user][i].lastClaimTime); //60; // Change according to your time
            uint256 rewardsSinceLastClaim = rewardPerMinute *
                minutesSinceLastClaim;
            totalRewards += rewardsSinceLastClaim;
        }
        uint256 earnedLeadershipRewards = calculateLeadershipRewards(user);
        totalRewards += earnedLeadershipRewards;
        return totalRewards;
    }

    function withdrawTeamBonus() public {
        (uint256 rankReward, uint256 teamCount) = teamBonus(msg.sender);
        LeadershipRewards storage leadersR = teamBonuses[msg.sender][1];
        require(
            rankReward > leadersR.starReceived,
            "No any Withdrawl Team Bonus Available"
        );
        rankReward = rankReward * 1 ether;
        uint256 fee = (rankReward * WITHDRAWAL_FEE_PERCENTAGE) / 100; // Calculate the fee (10% of the amount)
        token.transfer(msg.sender, rankReward - fee);
        token.transfer(admin, fee);
        totalRewardWithdraw[msg.sender] += rankReward;
        leadersR.totalRewardReceived += rankReward;
        leadersR.starReceived = rankReward;
        emit WithdrawTeamBonus(msg.sender, rankReward);
    }

    function getUserStakes(
        address _user
    ) external view returns (UserStakes[] memory) {
        return userStakes[_user];
    }
}
