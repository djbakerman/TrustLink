TrustLink - Automated Service Level Agreement Enforcement on the Blockchain

Synopsis:

TrustLink is on a mission to bring transparency and fairness into the world of service level agreements. We believe that trust is the cornerstone of any successful business relationship, and we're here to ensure that trust is never compromised.

Our platform is designed to keep service providers on their toes, encouraging them to always strive for excellence. With TrustLink, they know that their performance is continuously monitored against agreed-upon KPIs. If they meet or exceed these KPIs, they build trust and reputation. If they fall short, there are financial consequences, ensuring accountability. 

For the purpose of the Hackathon, we used the Azure Internet of Things Simulator to simulate our test point data but the real world any JSON otput should be sufficient.

But TrustLink isn't just about keeping service providers in check. It's also about giving clients peace of mind. With our platform, they can see exactly how their service providers are performing, eliminating any guesswork or disputes.

In essence, TrustLink is about creating a win-win situation for everyone involved. We're here to ensure that service level agreements are more than just words on a paper - they're commitments that are upheld and respected.

What?

TrustLink is a decentralized application (dApp) designed to enhance the way service level agreements (SLAs) are monitored and enforced in the data center and fiber networking industry. Built on the Ethereum blockchain and leveraging Chainlink oracles, TrustLink offers a transparent, secure, and automated solution for managing SLA compliance.

The platform continuously monitors key performance indicators (KPIs) and other data points, ensuring adherence to agreed-upon service levels between parties. In the event of an SLA violation, TrustLink's smart contracts automatically transfer funds from an escrow account to the recipients. Both parties agree on the appropriate compensation or negotiate the amount to be released from the escrow account.

By utilizing blockchain technology and smart contracts, TrustLink eliminates the need for manual intervention, significantly reducing the time and effort required to manage SLAs. The platform's decentralized nature ensures data integrity and fosters trust between parties, while its user-friendly interface makes it accessible to both technical and non-technical users.

TrustLink's innovative approach to SLA enforcement has the potential to streamline processes, reduce disputes, and ultimately enhance customer satisfaction in the data center and fiber networking industry.

How?

TrustLink uses several smart contracts to achieve its functionality:

Escrow: The Escrow contract is a crucial part of the TrustLink platform. It's responsible for managing the creation, negotiation, fulfillment, and recipient agreement status of escrows. This contract holds funds in a secure state until certain conditions are met, as defined by the service level agreements (SLAs).  When a KPI violation occurs, as detected by the KPI contract, the Escrow contract initiates the process of transferring funds from the escrow account to the designated recipient. This could be the service recipient in case of an SLA violation, or back to the service provider if the SLA is met successfully.

KPI: This is the main contract that interacts with the Chainlink network to fetch data from an external API. It manages the creation, updating, deletion, and fetching of KPI points and checks if a KPI has been violated.

Escrow Factory: The EscrowFactory contract is responsible for creating and managing multiple instances of the Escrow contract. Each instance corresponds to a unique escrow agreement between two parties.

IEscrow: This is an interface for the Escrow contract, which manages the creation, negotiation, fulfillment, and recipient agreement status of escrows.

IKPI: This is an interface for the KPI contract, which manages the creation, updating, deletion, and fetching of KPI points.

KPIFactory: This is a factory contract that manages the creation and retrieval of KPI contracts for each escrow.

Deployement and usage instructions (NOTE: This is for Sepolia Testnet):

Step 1: Compile KPIFactory and then deploy EscrowFactory passing the KPIFactory's address as the constructor.

Step 2: In the EscrowFactory, call the getOrCreateEscrowAccount

Step 3: Use the Escrow contrat at the address provided by the escrow factory's getOrCreateEscrowAccount

Step 4: Using the Escrow contract, createEscrow.  Pass the array of recipient addresses and the escrow amount in wei. Ensure the sender has the same amount of wei.

Step 5a: Either have all the recipents agree now or later by calling the setRecipientAgrees to true for the given escrow id.  The escrow will not fulfill without areAllRecipientsAgreed returning true.
Step 5b: Call the getOrCreateKPIForEscrow with the escrow id.  The first escrow is 0.

Step 6: Use the KPI contract at the address provided by the getOrCreateKPIForEscrow for the given escrow id.   Note: To find the KPI contract address, call the "escrows" function and it will return the KPI contract address.

Step 7: Fund the KPI contract with LINK.  10 LINK is a good starting point.

Step 8: Call the createKPIPoint function with the relevant point data. For the demo used: https://trustlinkstorage.blob.core.windows.net/trustlinktest/trustlink-dev/01/2023/0601/2249.json, "Body,Temperature", 80, 0
Note: Calling getEscrowKPIs with escrow id will display all the KPIs created for the given escrow.

Step 9: Register the KPI contract to the ChainLink Keeper network by calling the registerUpkeep function.

Use the other KPI functions as necessary, for example to change/delete KPI points.
