// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Escrow is the third party responsible for completing the transaction of buying/selling a real estate NFT
 */
contract Escrow {

    address public owner;

    address public nftContractAddress;
    uint256 nftId;

    //Buyer and seller approve the deal.
    address public buyer;
    address public seller;

    //Lender provides the loan and transfers the funds to Escrow.
    address public lender;

    //Verifier verifies the nft, provides the InspectionStatus and approves the deal.
    address public verifier;

    //After all approvals, payments are received by Escrow. 
    //Escrow transfers ownership of the nft to the buyer.
    //Escrow transfers the funds to seller
    uint256 public depositAmount;
    uint256 public purchaseAmount;
    uint256 public remainingPaymentAmount;

    mapping(address=>bool) public approvals;

    modifier onlyOwner() {
        require(owner == msg.sender, "Only the contract owner can run this function");
        _;
    }

    modifier onlyBuyer(){
        require(msg.sender == buyer, "Only the BUYER can pay the deposit");
        _;
    }

    modifier onlyVerifier(){
        require(verifier == msg.sender,"Only the VERIFIER can change the inspection status");
        _;
    }

    InspectionStatus public inspectionStatus;

    enum InspectionStatus {
        INITIATED,
        PASSED,
        FAILED
    }

    event RealEstateNFTTransferred(address from, address to, uint256 propertyNftId);
    event DepositPaid(address from, uint256 propertyNftId, uint256 amount);
    event ApprovalGiven(address from, uint256 propertyNftId);
    event RemainingPaymentDone(address from, uint256 propertyNftId, uint256 amount);
    event InspectionStatusUpdated(uint256 propertyNftId, InspectionStatus status);

    constructor(address _nftContractAddress, uint256 _nftId, address _seller, address _buyer, 
        address _lender, address _verifier, uint256 _purchaseAmount, uint256 _depositAmount) {
        nftContractAddress = _nftContractAddress;
        nftId = _nftId;
        seller = _seller;
        buyer = _buyer;
        lender = _lender;
        verifier = _verifier;
        purchaseAmount = _purchaseAmount;
        depositAmount = _depositAmount;
        remainingPaymentAmount = _purchaseAmount;
        inspectionStatus = InspectionStatus.INITIATED;
        owner = msg.sender;
    }

    /**
     * @dev this function transfers the nft from seller to buyer
     */
    function transferProperty() public onlyOwner{
        require(inspectionStatus == InspectionStatus.PASSED, "Inspection status must be PASSED");

        require(approvals[buyer] == true, "Must be approved by Buyer");
        require(approvals[seller] == true, "Must be approved by Seller");
        require(approvals[lender] == true, "Must be approved by Lender");

        require(remainingPaymentAmount==0, "Some payment still remaining.");

        require(address(this).balance == purchaseAmount, "Not enough balance");

        (bool res,) = payable(seller).call{value : address(this).balance}("");
        require(res);

        (IERC721)(nftContractAddress).safeTransferFrom(seller, buyer, nftId);

        emit RealEstateNFTTransferred(seller, buyer, nftId);
    }

    /**
     * @dev this function provides approval to the deal. 
     * whoever calls this function, their approval will be set accordingly
     * @param approval true/false value
     */
    function provideApproval(bool approval) public {
        approvals[msg.sender] = approval;
        emit ApprovalGiven(msg.sender, nftId);
    }

    /**
     * @dev this function is to pay the deposit
     */
    function payDeposit() public payable onlyBuyer{
        require(msg.value >= depositAmount, "Deposit amount is not enough");
        remainingPaymentAmount = purchaseAmount - msg.value;

        emit DepositPaid(msg.sender, nftId, msg.value);
    }

    /**
     * @dev this function is to pay the remaining amount
     */
    function payRemainingAmount() public payable{
        require(remainingPaymentAmount>0, "Nothing left to pay. All payments done");
        require(msg.value > 0, "Amount should be greater than 0");
        require(msg.value <= remainingPaymentAmount, "Amount is more than required.");
        remainingPaymentAmount = remainingPaymentAmount - msg.value;

        emit RemainingPaymentDone(msg.sender, nftId, msg.value);
    }

    /**
     * @dev only the verifier can update the inspection status
     */
    function updateInspectionStatus(InspectionStatus _status) public onlyVerifier{
        
        inspectionStatus = _status;
        emit InspectionStatusUpdated(nftId, _status);
    }

    /**
     * @dev this function sets the purchase amount in case the original value needs to be overriden
     */
    function setPurchaseAmount(uint256 _purchaseAmount) public onlyOwner{
        require(_purchaseAmount>0, "Purchase amount should be greater than 0");
        purchaseAmount=_purchaseAmount;        
    }

    /**
     * @dev this function sets the deposit amount in case the original value needs to be overriden
     */
    function setDepositAmount(uint256 _depositAmount) public onlyOwner{
        require(_depositAmount>0, "Deposit amount should be greater than 0");
        depositAmount=_depositAmount;   
    }

    /**
     * @dev get ETH balance of the contract
     */
    function getBalance() public view returns(uint256 balance){
        return address(this).balance;
    }

    /**
     * @dev returns balance of given wallet address
     * @return balance balance of the wallet
     */
    function getBalanceOf(address walletAddress) public view returns(uint256 balance){
        return walletAddress.balance;
    }
}
