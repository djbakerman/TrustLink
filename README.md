TrustLink - Automated Service Level Agreement Enforcement on the Blockchain

Synopsis:

TrustLink is on a mission to bring transparency and fairness into the world of service level agreements. We believe that trust is the cornerstone of any successful business relationship, and we're here to ensure that trust is never compromised.

Our platform is designed to keep service providers on their toes, encouraging them to always strive for excellence. With TrustLink, they know that their performance is continuously monitored against agreed-upon KPIs. If they meet or exceed these KPIs, they build trust and reputation. If they fall short, there are consequences, ensuring accountability.

But TrustLink isn't just about keeping service providers in check. It's also about giving clients peace of mind. With our platform, they can see exactly how their service providers are performing, eliminating any guesswork or disputes.

In essence, TrustLink is about creating a win-win situation for everyone involved. We're here to ensure that service level agreements are more than just words on a paper - they're commitments that are upheld and respected.

What?

TrustLink is a decentralized application (dApp) designed to enhance the way service level agreements (SLAs) are monitored and enforced in the data center and fiber networking industry. Built on the Ethereum blockchain and leveraging Chainlink oracles, TrustLink offers a transparent, secure, and automated solution for managing SLA compliance.

The platform continuously monitors key performance indicators (KPIs) and other data points, ensuring adherence to agreed-upon service levels between parties. In the event of an SLA violation, TrustLink's smart contracts automatically transfer funds from an escrow account to the recipients. Both parties agree on the appropriate compensation or negotiate the amount to be released from the escrow account.

By utilizing blockchain technology and smart contracts, TrustLink eliminates the need for manual intervention, significantly reducing the time and effort required to manage SLAs. The platform's decentralized nature ensures data integrity and fosters trust between parties, while its user-friendly interface makes it accessible to both technical and non-technical users.

TrustLink's innovative approach to SLA enforcement has the potential to streamline processes, reduce disputes, and ultimately enhance customer satisfaction in the data center and fiber networking industry.

How?

TrustLink uses several smart contracts to achieve its functionality:

IEscrow: This is an interface for the Escrow contract, which manages the creation, negotiation, fulfillment, and recipient agreement status of escrows.
IKPI: This is an interface for the KPI contract, which manages the creation, updating, deletion, and fetching of KPI points.
KPI: This is the main contract that interacts with the Chainlink network to fetch data from an external API. It manages the creation, updating, deletion, and fetching of KPI points and checks if a KPI has been violated.
KPIFactory: This is a factory contract that manages the creation and retrieval of KPI contracts for each escrow.

Basic Instructions:

Step 1: Connect Your Wallet
First, you'll need to connect your MetaMask wallet. This is a secure and user-friendly way to manage your Ethereum transactions. If you don't have a MetaMask wallet yet, you can download it as a browser extension and set up an account.

Step 2: Access the TrustLink Platform
Once your wallet is connected, navigate to the TrustLink platform. Here, you'll be able to interact with our smart contracts and manage your service level agreements (SLAs).

Step 3: Create or Access an Escrow Account
Click on the getOrCreateEscrowAccount button. This will link the Escrow.sol contract to your MetaMask wallet. You'll then be presented with the methods and variables of the Escrow.sol smart contract.

Step 4: Fund Your Escrow
Next, you'll need to fund your escrow. You can do this by interacting with the createEscrow function. This will transfer funds from your wallet to the escrow account.

Step 5: Link the KPI Contract
Click on getOrCreateKPIForEscrow. This will link the KPI.sol contract to the corresponding escrow ID. You'll then be presented with the methods and variables of the KPI.sol smart contract.

Step 6: Fund the KPI Contract
Before setting your KPIs, you'll need to fund the KPI contract with LINK tokens. This is necessary for the contract to interact with the Chainlink network. You can do this by interacting with the fundKPIContract function.

Step 7: Set Your KPIs
Now, it's time to set your key performance indicators (KPIs). Enter your KPIs into the platform. The KPI.sol contract will then create a Chainlink for monitoring the KPIs on a schedule.

Step 8: Monitor Your KPIs
If any Chainlink oracle returns a KPI violation, it will notify the KPI.sol contract. The contract will then initiate the fulfillEscrow function of the Escrow.sol contract, which will proceed with the escrow fulfillment process.
