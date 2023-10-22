import { ethers } from "https://cdnjs.cloudflare.com/ajax/libs/ethers/6.7.0/ethers.min.js";

let signer = null;
let provider;

let userTokens = [];

let chart;
let data;

if (window.ethereum == null) {
    console.log("MetaMask not installed; using read-only defaults");
    provider = ethers.getDefaultProvider();
} else {
    provider = new ethers.BrowserProvider(window.ethereum)

    let loginBtn = document.getElementById("login-btn");
    signer = await provider.getSigner();

    // Replace the login button with the address
    const address = await signer.getAddress();
    loginBtn.innerHTML = address;
}

const contractAddress = "0xE3c61D89E14EE6bbcab5925ae2edf11c268047E6";
const contractABI = [
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": false,
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "fee",
                "type": "uint256"
            }
        ],
        "name": "FlashLoan",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "user",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "feeLevel",
                "type": "uint256"
            }
        ],
        "name": "TokenDeposited",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "user",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "feeLevel",
                "type": "uint256"
            }
        ],
        "name": "TokenWithdrawn",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "fee",
                "type": "uint256"
            }
        ],
        "name": "deposit",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "feeLevel",
                "type": "uint256"
            }
        ],
        "name": "distributeRewards",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "contract IERC3156FlashBorrower",
                "name": "receiver",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
            }
        ],
        "name": "flashLoan",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "fee",
                "type": "uint256"
            }
        ],
        "name": "withdraw",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "flashFee",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "token",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "flashFeeAndOvershoot",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "name": "lowestFeeAmount",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "token",
                "type": "address"
            }
        ],
        "name": "maxFlashLoan",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "pools",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "thisFeeAmount",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "rewardPerToken",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "previousFee",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "nextFee",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "REWARD_FEE_DIVISOR",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "name": "totalAvailable",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "userInfo",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "rewardDebt",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
];

const ERC20ABI = [
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "owner",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "spender",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Approval",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "from",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "to",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Transfer",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "owner",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "spender",
                "type": "address"
            }
        ],
        "name": "allowance",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "spender",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "approve",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "totalSupply",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "transfer",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "transferFrom",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    }
];

const contract = new ethers.Contract(contractAddress, contractABI, signer);

const depositBtn = document.getElementById("deposit-btn");
depositBtn.addEventListener("click", async (event) => {
    // Cancel the default action, if needed
    event.preventDefault();
    const value = document.getElementById("deposit-input").value;
    const fee = document.getElementById("deposit-fee-input").value * 10_000;
    console.log(fee);
    const token = document.getElementById("token-select").value;

    const amount = ethers.parseEther(value);
    const tokenContract = new ethers.Contract(token, ERC20ABI, signer);
    const allowance = await tokenContract.allowance(await signer.getAddress(), contractAddress);
    if (allowance < amount) {
        const tx = await tokenContract.approve(contractAddress, amount);
        await tx.wait();
        console.log("Approval successful");
    }
    const tx = await contract.deposit(token, amount, fee);
    await tx.wait();
    console.log("Deposit successful");

    // Refresh page after action to reload all items
    reloadPositions();
    createChart();
});

async function reloadPositions() {
    const address = await signer.getAddress();
    const filter = contract.filters.TokenDeposited(address);
    const events = await contract.queryFilter(filter);
    const tokens = events.map((event) => event.args[1]).filter((value, index, self) => self.indexOf(value) === index);
    userTokens = [];
    for (const token of tokens) {
        const fees = events
            // Only get events for this token
            .filter((event) => event.args[1] === token)
            // Get the fee levels
            .map((event) => event.args[3])
            // Make them unique
            .filter((value, index, self) => self.indexOf(value) === index);
        for (const fee of fees) {
            const userInfo = await contract.userInfo(address, token, fee);

            // TODO: Fetch token decimals
            if (userInfo[0] > 0)
                userTokens.push({ token: token, feeLevel: fee, userInfo: userInfo });
        }
    }

    const table = document.getElementById("my-positions");
    table.innerHTML = "";
    for (const index in userTokens) {
        const userToken = userTokens[index];
        // TODO: fetch token symbol
        const row = table.insertRow();
        row.className = "text-sm font-medium text-left text-gray-700 border-b border-gray-200";

        const feeCell = row.insertCell();
        feeCell.className = "px-4 py-3 border";
        const amountCell = row.insertCell();
        amountCell.className = "px-4 py-3 border";
        const withdrawCell = row.insertCell();
        withdrawCell.className = "px-4 py-3 border";
        // Make a button to withdraw
        const withdrawBtn = document.createElement("button");
        withdrawBtn.innerHTML = "Withdraw";
        withdrawBtn.className = "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded";
        withdrawBtn.addEventListener("click", async (event) => {
            // Cancel the default action, if needed
            event.preventDefault();

            const tx = await contract.withdraw(userToken.token, userToken.userInfo[0], userToken.feeLevel);
            await tx.wait();
            console.log("Withdrawal successful");

            // Refresh page after action to reload all items
            reloadPositions();
            createChart();
        });
        withdrawCell.appendChild(withdrawBtn);

        feeCell.innerHTML = Number(userToken.feeLevel) / 10000 + "%";
        amountCell.innerHTML = ethers.formatEther(userToken.userInfo[0]);
    }
}

async function createChart() {
    // Get the canvas element from the HTML
    const chartCanvas = document.getElementById('chart');

    // Fetch the data from the smart contract
    const token = document.getElementById("token-select").value;
    // Fetch the token fee amount (start of a linked list)
    const lowestFeeAmount = await contract.lowestFeeAmount(token);

    // Fetch the data for the chart
    data = [];
    let currentFee = lowestFeeAmount;
    while (currentFee > 0) {
        const pool = await contract.pools(token, currentFee);
        data.push({ fee: currentFee, amount: pool.thisFeeAmount, pool: pool });
        currentFee = pool.nextFee;
    }

    if (chart) {
        chart.destroy();
    }

    // Create the chart
    chart = new Chart(chartCanvas, {
        type: 'line',
        data: {
            labels: data.map((value) => Number(value.fee) / 10_000 + "%"),
            datasets: [{
                data: data.map((value) => value.amount).reduce((acc, amount, idx) => {
                    if (idx === 0) {
                        acc.push(amount);
                    } else {
                        acc.push(acc[idx - 1] + amount);
                    }
                    return acc;
                }, []).map((value) => ethers.formatEther(value)),
                borderColor: 'rgb(66,153,225)',
                tension: 0.1
            }]
        },
        options: {
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                x: {
                    title: {
                        display: true,
                        text: 'Fee (%)'
                    }
                },
                y: {
                    title: {
                        display: true,
                        text: 'Total deposit amount (DUM)'
                    },
                    beginAtZero: true
                }
            }
        }
    });
}

async function calculateRewards() {
    // userTokens are { token: token, feeLevel: fee, userInfo: userInfo }
    // data is { fee: fee, amount: amount, pool: pool }
    // userTokensWithRewards are { token: token, feeLevel: fee, userInfo: userInfo, rewardPerToken: rewardPerToken }
    // Match the fee levels of the userTokens to the data
    const userTokensWithRewards = userTokens.map((userToken) => {
        const dataItem = data.find((dataItem) => dataItem.fee === userToken.feeLevel);
        return { ...userToken, rewardPerToken: dataItem.pool.rewardPerToken };
    });

    const table = document.getElementById("my-rewards");
    table.innerHTML = "";

    for(const index in userTokensWithRewards) {
        const userTokenWithRewards = userTokensWithRewards[index];
        // Check if user has rewards for token and fee level
        const rewards = userTokenWithRewards.userInfo[0] * (BigInt(userTokenWithRewards.rewardPerToken) - BigInt(userTokenWithRewards.userInfo[1])) / BigInt(1_000_000);


        if (rewards == 0) {
            console.log("No rewards for", userTokenWithRewards.token, userTokenWithRewards.feeLevel);
            continue;
        }

        const row = table.insertRow();
        row.className = "text-sm font-medium text-left text-gray-700 border-b border-gray-200";
        const feeCell = row.insertCell();
        feeCell.className = "px-4 py-3 border";
        const rewardCell = row.insertCell();
        rewardCell.className = "px-4 py-3 border";
        const retrieveCell = row.insertCell();
        retrieveCell.className = "px-4 py-3 border";
        // Make a button to withdraw
        const retrieveBtn = document.createElement("button");
        retrieveBtn.innerHTML = "Retrieve";
        retrieveBtn.className = "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded";
        retrieveBtn.addEventListener("click", async (event) => {
            // Cancel the default action, if needed
            event.preventDefault();

            const tx = await contract.distributeRewards(userTokenWithRewards.token, userTokenWithRewards.feeLevel);
            await tx.wait();
            console.log("Retrieve successful");

            // Refresh page after action to reload all items
            reloadData();
        });
        retrieveCell.appendChild(retrieveBtn);

        feeCell.innerHTML = Number(userTokenWithRewards.feeLevel) / 10000 + "%";
        rewardCell.innerHTML = ethers.formatEther(rewards);
    }
}

async function reloadData() {
    await Promise.all([
        reloadPositions(),
        createChart()
    ]);

    calculateRewards();
}
reloadData();