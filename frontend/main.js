import { ethers } from "https://cdnjs.cloudflare.com/ajax/libs/ethers/6.7.0/ethers.min.js";

let signer = null;
let provider;

let userTokens = [];

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

const contractAddress = "0xEA885F53451044b6D8F0A3134bcFeb6302beB19c";
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
    const fee = document.getElementById("deposit-fee-input").value;
    const token = document.getElementById("deposit-select").value;

    const amount = ethers.parseEther(value);
    const tokenContract = new ethers.Contract(token, ERC20ABI, signer);
    const allowance = await tokenContract.allowance(await signer.getAddress(), contractAddress);
    console.log(allowance);
    console.log(amount);
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
});

// const withdrawBtn = document.getElementById("withdraw-btn");
// withdrawBtn.addEventListener("click", async (event) => {
//     // Cancel the default action, if needed
//     event.preventDefault();
//     const value = document.getElementById("withdraw-input").value;
//     const token = document.getElementById("withdraw-select").value;
//     const fee = document.getElementById("withdraw-fee-input").value;

//     const amount = ethers.parseEther(value);
//     const tx = await contract.withdraw(token, amount, fee);
//     await tx.wait();
//     console.log("Withdrawal successful");
// });

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
            userTokens.push({token: token, feeLevel: fee, userInfo: userInfo});
        }
    }

    console.log(userTokens);

    const table = document.getElementById("my-positions");
    table.innerHTML = "";
    for (const index in userTokens) {
        const userToken = userTokens[index];
        // TODO: fetch token symbol
        const row = table.insertRow();
        row.className = "text-sm font-medium text-left text-gray-700 border-b border-gray-200";

        const tokenCell = row.insertCell();
        tokenCell.className = "px-4 py-3 border";
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

            const amount = ethers.parseEther(value);
            const tx = await contract.withdraw(token, amount, fee);
            await tx.wait();
            console.log("Withdrawal successful");
        });
        withdrawCell.appendChild(withdrawBtn);

        tokenCell.innerHTML = userToken.token.substring(0, 6) + "..." + userToken.token.substring(38);
        feeCell.innerHTML = Number(userToken.feeLevel) / 1000000 + "%";
        amountCell.innerHTML = ethers.formatEther(userToken.userInfo[0]);
    }
}

reloadPositions();