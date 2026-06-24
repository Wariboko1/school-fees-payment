// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract SchoolFeesPayment {
    address public schoolAdmin;
    // 1. The address of the school admin

    bool public isPaymentPortalOpen;
    event Withdrawn(address indexed admin, uint256 amount);
    // 2. Whether the payment portal is open or closed

    uint256 public paymentDeadline;
    // 3. The payment deadline

    uint256 public extraPenalty;
    // 4. Late payment penalty amount in ETH

    mapping(string => mapping(uint256 => uint256)) public feeAmount;
    // 5. Store fees amount per faculty per level

    struct Student {
        string matricNumber;
        string faculty;
        uint256 level;
        address walletAddress;
        bool hasPaid;
        uint256 amountPaid;
        uint256 paymentTime;
    }

    mapping(string => Student) public students;

    mapping(address => string) public walletToMatricNumber;
    // 8. Link parent wallet address
    //    to student matric number

    event PortalStatusChanged(bool isOpen);
    // 9. Announce when portal opens or closes
    event PaymentStatusChanged(
        string indexed matricNumber,
        bool hasPaid,
        uint256 amountPaid,
        uint256 paymentTime
    );
    // 10. Announce when student pays
    event PaymentReminder(string indexed matricNumber, uint256 deadline);
    // 11. Announce when student has not paid by deadline
    event SchoolManagementAnnouncement(
        string indexed matricNumber,
        uint256 amountPaid,
        uint256 paymentTime
    );
    // 12. Announce when school management
    //     is notified of payment

    constructor() {
        schoolAdmin = msg.sender; // set deployer as admin
        isPaymentPortalOpen = false; // portal starts closed
    }

    modifier onlySchoolAdmin() {
        require(
            msg.sender == schoolAdmin,
            "Only school admin can perform this action"
        );
        _; // this means "now run the function"
    }

    modifier portalMustBeOpen() {
        require(isPaymentPortalOpen, "Payment portal is currently closed");
        _;
    }

    function registerStudent(
        string memory matricNumber,
        string memory faculty,
        uint256 level,
        address walletAddress
    ) public onlySchoolAdmin {
        require(
            bytes(students[matricNumber].matricNumber).length == 0,
            "Students already exist"
        );
        students[matricNumber] = Student({
            matricNumber: matricNumber,
            faculty: faculty,
            level: level,
            walletAddress: walletAddress,
            hasPaid: false,
            amountPaid: 0,
            paymentTime: 0
        });

        walletToMatricNumber[walletAddress] = matricNumber;
        emit StudentRegistered(matricNumber, faculty, level);
    }

    function setPortalStatus(bool status) public onlySchoolAdmin {
        isPaymentPortalOpen = status;
        emit PortalStatusChanged(status);
    }

    function setFees(
        string memory faculty,
        uint256 level,
        uint256 amount
    ) public onlySchoolAdmin {
        require(!isPaymentPortalOpen, "Close the portal before updating fees");

        feeAmount[faculty][level] = amount;
    }

    function setPaymentDeadline(uint256 deadline) public onlySchoolAdmin {
        require(
            !isPaymentPortalOpen,
            "Close the portal before setting deadline"
        );

        require(deadline > block.timestamp, "Deadline must be in the future");

        paymentDeadline = deadline;
    }

    function setExtraPenalty(uint256 penalty) public onlySchoolAdmin {
        require(
            !isPaymentPortalOpen,
            "Close the portal before setting the penalty"
        );

        require(penalty > 0, "Penalty must be greater than 0");

        extraPenalty = penalty;
    }

    function sendPaymentReminder(
        string memory matricNumber
    ) public onlySchoolAdmin {
        require(
            bytes(students[matricNumber].matricNumber).length > 0,
            "Student not found"
        );

        require(!students[matricNumber].hasPaid, "Students has already paid");

        require(
            block.timestamp < paymentDeadline,
            "Payment deadline has passed"
        );

        emit PaymentReminder(matricNumber, paymentDeadline);
    }

    function paySchoolFees(
        string memory matricNumber
    ) public payable portalMustBeOpen {
        require(
            bytes(students[matricNumber].matricNumber).length > 0,
            "Students not found"
        );

        require(!students[matricNumber].hasPaid, "Students has already paid");

        string memory faculty = students[matricNumber].faculty;
        uint256 level = students[matricNumber].level;
        uint256 requiredAmount = feeAmount[faculty][level];

        if (block.timestamp > paymentDeadline) {
            requiredAmount = requiredAmount + extraPenalty;
        }

        require(msg.value == requiredAmount, "Incorrect payment amount");

        students[matricNumber].hasPaid = true;
        students[matricNumber].amountPaid = msg.value;
        students[matricNumber].paymentTime = block.timestamp;

        emit PaymentStatusChanged(
            matricNumber,
            true,
            msg.value,
            block.timestamp
        );
        emit SchoolManagementAnnouncement(
            matricNumber,
            msg.value,
            block.timestamp
        );
    }

    function checkPaymentStatus(
        string memory matricNumber
    ) public view returns (bool, uint256, uint256) {
        require(
            bytes(students[matricNumber].matricNumber).length > 0,
            "Student does not exist"
        );

        return (
            students[matricNumber].hasPaid,
            students[matricNumber].amountPaid,
            students[matricNumber].paymentTime
        );
    }

   function withdraw() public onlySchoolAdmin {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to withdraw");

    (bool success, ) = payable(schoolAdmin).call{value: balance}("");
    require(success, "Withdrawal failed");
}
    event StudentRegistered(
        string indexed matricNumber,
        string faculty,
        uint256 level
    );

    receive() external payable {}
}
