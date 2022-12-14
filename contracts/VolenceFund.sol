// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VolenceFund {
    using SafeMath for uint256;
    address payable owner;
    uint private treasury;

    enum State {
        Funding,
        Expired,
        Funded
    }

    constructor() {
        owner = payable(msg.sender);
    }

    struct Category {
        uint categoryId;
        string name;
        string image;
        string desc;
    }

    struct Project {
        uint OrgainizationId;
        address payable Creator;
        string Title;
        string Description;
        uint Target;
        uint CapitalRaised;
        uint Deadline;
        string Location;
        Category Category;
        string Img;
        State state;
        uint noOfContribution;
        uint numRequests;
        Request[] requests;
    }

    struct volunteer {
        string name;
        string desc;
        string image;
        uint volunteerId;
        string role;
        string email;
        string phone;
        string location;
        bool active;
        Project[] assignedProjects;
        address volunteerAddress;
    }

    struct Request {
        uint requestId;
        string desc;
        uint value;
        address payable receipient;
        bool status;
        uint noOfVoter;
    }

    struct Voters {
        uint requestId;
        mapping(address => bool) vote;
    }

    struct Contributions {
        uint projectId;
        mapping(address => uint) contributions;
        Voters[] voters;
    }

    Contributions[] listofContributions;

    uint counterProjectId;
    uint counterVolunteerId;
    uint countCategoryId;

    Project[] projects;
    volunteer[] volunteers;
    Category[] categories;

    event FundReceiced(address contributor, uint amount, uint currentTotal);

    event CreatorPaid(address recipient);

    function registerasAsVolunteer(
        string memory _name,
        string memory _desc,
        string memory _image,
        string memory _role,
        string memory _location,
        string memory _email,
        string memory _phone
    ) public returns (uint) {
        volunteers.push();
        uint index = volunteers.length - 1;
        volunteers[index].name = _name;
        volunteers[index].desc = _desc;
        volunteers[index].image = _image;
        volunteers[index].role = _role;
        volunteers[index].email = _email;
        volunteers[index].phone = _phone;
        volunteers[index].location = _location;
        volunteers[index].volunteerId = index;
        volunteers[index].active = false;
        volunteers[index].volunteerAddress = msg.sender;
        counterVolunteerId++;

        return volunteers[index].volunteerId;
    }

    function createCategory(
        string memory _name,
        string memory _desc,
        string memory _image
    ) public returns (uint) {
        bool isApprovedVoleunteer = false;
        for (uint i = 0; i < counterVolunteerId - 1; i++) {
            if (
                volunteers[i].volunteerAddress == msg.sender &&
                volunteers[i].active
            ) {
                isApprovedVoleunteer = true;
                break;
            }
        }
        require(
            msg.sender == owner || isApprovedVoleunteer,
            "Only owner or active voleunteer approve volunteer"
        );
        categories.push();
        uint index = categories.length - 1;

        categories[index].name = _name;
        categories[index].desc = _desc;
        categories[index].image = _image;
        categories[index].categoryId = index;
        countCategoryId++;
        return categories[index].categoryId;
    }

    function createCauseProject(
        string memory _projectTitle,
        string memory _projectDesc,
        uint _fundRaisingDeadline,
        uint _goalAmount,
        uint _volenuteerId,
        string memory _location,
        uint _category,
        string memory _imgUri
    ) public returns (uint) {
        projects.push();
        listofContributions.push();
        uint index = projects.length - 1;

        projects[index].OrgainizationId = counterProjectId;
        projects[index].Title = _projectTitle;
        projects[index].Description = _projectDesc;
        projects[index].Target = _goalAmount;
        projects[index].CapitalRaised = 0;
        projects[index].Deadline = _fundRaisingDeadline;
        projects[index].Location = _location;
        projects[index].Category = categories[_category];
        projects[index].Img = _imgUri;
        projects[index].state = State.Funding;

        listofContributions[index].projectId = counterProjectId;
        counterProjectId++;

        volunteers[_volenuteerId].assignedProjects.push(projects[index]);
        return projects[index].OrgainizationId;
    }

    function checkIfFundingCompleteOrExpired(uint _projectId) public {
        if (projects[_projectId].CapitalRaised >= projects[_projectId].Target) {
            projects[_projectId].state = State.Funded;
        } else if (block.timestamp > projects[_projectId].Deadline) {
            projects[_projectId].state = State.Expired;
        } else {
            projects[_projectId].state = State.Funding;
        }
    }

    function contribute(uint _projectId) external payable returns (bool) {
        require(
            msg.sender != projects[_projectId].Creator,
            "Project creator can't contribute"
        );
        checkIfFundingCompleteOrExpired(_projectId);
        require(
            projects[_projectId].state == State.Funding,
            "Project not expired, can't refund"
        );
        projects[_projectId].CapitalRaised = projects[_projectId]
            .CapitalRaised
            .add(msg.value);
        listofContributions[_projectId].contributions[
            msg.sender
        ] = listofContributions[_projectId].contributions[msg.sender].add(
            msg.value
        );
        emit FundReceiced(
            msg.sender,
            msg.value,
            projects[_projectId].CapitalRaised
        );

        if (listofContributions[_projectId].contributions[msg.sender] == 0) {
            projects[_projectId].noOfContribution++;
        }

        return true;
    }

    function getRefund(uint _projectId) public returns (bool) {
        checkIfFundingCompleteOrExpired(_projectId);
        require(
            projects[_projectId].state == State.Expired,
            "Project not expired, can't refund"
        );
        require(
            listofContributions[_projectId].contributions[msg.sender] > 0,
            "You have not contribute to this project"
        );
        uint amountTorefund = listofContributions[_projectId].contributions[
            msg.sender
        ];
        listofContributions[_projectId].contributions[msg.sender] = 0;
        address payable sender = payable(msg.sender);
        if (!sender.send(amountTorefund)) {
            listofContributions[_projectId].contributions[
                msg.sender
            ] = amountTorefund;
        } else {
            projects[_projectId].CapitalRaised = projects[_projectId]
                .CapitalRaised
                .sub(amountTorefund);
        }
        return true;
    }

    function approveVolunteer(uint volunterrId) public returns (bool) {
        bool isApprovedVoleunteer = false;
        for (uint i = 0; i < counterVolunteerId - 1; i++) {
            if (
                volunteers[i].volunteerAddress == msg.sender &&
                volunteers[i].active
            ) {
                isApprovedVoleunteer = true;
                break;
            }
        }
        require(
            msg.sender == owner || isApprovedVoleunteer,
            "Only owner or active voleunteer approve volunteer"
        );
        volunteers[volunterrId].active = true;
        return true;
    }

    function createRequest(
        uint _projectId,
        string memory _desc,
        uint _value,
        address payable _receipient
    ) public {
        require(
            projects[_projectId].state == State.Funded,
            "Project expired or Successful can't create Request"
        );
        require(
            msg.sender == projects[_projectId].Creator,
            "only manager can create Request"
        );
        require(
            _value <= projects[_projectId].CapitalRaised,
            "withdraw is more than balance"
        );

        projects[_projectId].requests.push();
        listofContributions[_projectId].voters.push();
        uint requestIndex = projects[_projectId].requests.length - 1;

        projects[_projectId].requests[requestIndex].desc = _desc;
        projects[_projectId].requests[requestIndex].value = _value;
        projects[_projectId].requests[requestIndex].receipient = _receipient;
        projects[_projectId].requests[requestIndex].requestId = requestIndex;
        projects[_projectId].numRequests++;
    }

    function sendPayout(
        uint _projectId,
        address payable _address,
        uint _value,
        uint _requestNo
    ) private returns (bool) {
        Request storage thisRequest = projects[_projectId].requests[_requestNo];
        require(
            thisRequest.noOfVoter >=
                projects[_projectId].noOfContribution.div(2),
            "Conditon not fulfilled yet"
        );
        uint amountToTransfer = (_value * 97) / 100;
        uint fee = (_value * 3) / 100;
        treasury += fee;
        if (_address.send(amountToTransfer)) {
            emit CreatorPaid(_address);
            owner.transfer(fee);
            projects[_projectId].CapitalRaised = projects[_projectId]
                .CapitalRaised
                .sub(_value);
            return true;
        } else {
            return false;
        }
    }

    function voteRequest(uint _projectId, uint _requestNo) public {
        require(
            projects[_projectId].state == State.Funded,
            "project expired or successful can't create vote request"
        );
        require(
            listofContributions[_projectId].contributions[msg.sender] > 0,
            "you must be contribute to vote"
        );
        require(
            listofContributions[_projectId].voters[_requestNo].vote[
                msg.sender
            ] == false,
            "you have alredy voted"
        );
        projects[_projectId].requests[_requestNo].noOfVoter++;
        listofContributions[_projectId].voters[_requestNo].vote[
            msg.sender
        ] = true;

        if (
            projects[_projectId].requests[_requestNo].noOfVoter * 2 >=
            projects[_projectId].noOfContribution &&
            projects[_projectId].requests[_requestNo].value <=
            projects[_projectId].CapitalRaised
        ) {
            projects[_projectId].requests[_requestNo].status = true;
            sendPayout(
                _projectId,
                projects[_projectId].requests[_requestNo].receipient,
                projects[_projectId].requests[_requestNo].value,
                _requestNo
            );
        }
    }

    function getProjectByCategoryId(
        uint _categoryId
    ) public view returns (Project[] memory) {
        uint currentProjectId = counterProjectId - 1;
        uint categoryId = 0;
        Project[] memory categoryProjects;
        for (uint i = 0; i <= currentProjectId; i++) {
            if (projects[i].Category.categoryId == _categoryId) {
                categoryProjects[categoryId] = projects[i];
            }
        }
        return categoryProjects;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getAllProjects() public view returns (Project[] memory) {
        return projects;
    }

    function myContributions(
        uint _projectId,
        address _address
    ) public view returns (uint) {
        return listofContributions[_projectId].contributions[_address];
    }

    function getAllRequests(
        uint _projectId
    ) public view returns (Request[] memory) {
        return projects[_projectId].requests;
    }

    function getProjectById(
        uint _projectId
    ) public view returns (Project memory) {
        return projects[_projectId];
    }

    function getVolunterById(
        uint _volunterById
    ) public view returns (volunteer memory) {
        return volunteers[_volunterById];
    }
}
