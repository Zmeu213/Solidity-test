pragma solidity 0.4.11;

contract mortal {
    address owner;
    modifier onlyOwner() { if (msg.sender == owner) _; }
    function mortal() { owner = msg.sender; }
    function kill() { if (msg.sender == owner) selfdestruct(owner); }
}

contract ValidatorNetwork is mortal {
    //data
    struct Voting {
        address applicantAddress;
        string name;
        uint votesYes;
        uint votesNo;
        uint timeStart;
        bool isDone;
        uint votingID;
        mapping (address => bool) alreadyVoted;
    }
    mapping (address => bool) IsValidator;
    mapping (address => string) ValidatorName;
    Voting[] public CurrentVotes;
    uint validatorsCount;
    uint minimumVotingTime;
    uint maximumVotingTime;
    //events
    event validatorAdded(address _address, string _validatorName);
    event votingStarted(address _address, string _applicantName);
    event votingEnded(string _name, bool _result);
    event voteFor(string _name, string _forwho, bool _vote);
    //functions
    function ValidatorNetwork(string _ownerName, uint _minimumVotingTime, uint _maximumVotingTime) {
        if (_minimumVotingTime >= 0 && _maximumVotingTime > 0) {
            IsValidator[owner] = true;
            ValidatorName[owner] = _ownerName;
            validatorsCount += 1;
            minimumVotingTime = _minimumVotingTime * 1 days;
            maximumVotingTime = _maximumVotingTime * 1 days;
        } else {
            throw;
        }
    }

    function ApplyToPositionOfValidator(string _name) public onlyNotValidator() {
        Voting memory newVoting;
        newVoting = Voting({
            applicantAddress: msg.sender,
            name: _name,
            votesYes: 0,
            votesNo:  0,
            timeStart: now,
            isDone: false,
            votingID: CurrentVotes.length
            });
        CurrentVotes.push(newVoting);
        votingStarted(msg.sender, _name);
    }

    function Vote(uint voting, bool vote) public onlyValidator() {
        if (!CurrentVotes[voting].isDone && !CurrentVotes[voting].alreadyVoted[msg.sender]) {
            if (vote) 
                CurrentVotes[voting].votesYes += 1;
            else
                CurrentVotes[voting].votesNo += 1;
            CurrentVotes[voting].alreadyVoted[msg.sender] = true;
            voteFor(ValidatorName[msg.sender], CurrentVotes[voting].name, vote);
            checkVotings();
        }
    }

    function checkVotings() internal {
        if (CurrentVotes.length > 0) {
            for (uint i = 0; i < CurrentVotes.length; i++) {
                if (!CurrentVotes[i].isDone) {
                    if (CheckIfVotingDone(CurrentVotes[i])) {
                        CurrentVotes[i].isDone = true;
                        if (VotingResult(CurrentVotes[i])) {
                            IsValidator[CurrentVotes[i].applicantAddress] = true;
                            ValidatorName[CurrentVotes[i].applicantAddress] = CurrentVotes[i].name;
                            validatorsCount += 1;
                            votingEnded(CurrentVotes[i].name, true);
                            validatorAdded(CurrentVotes[i].applicantAddress, CurrentVotes[i].name);
                        } else {
                            votingEnded(CurrentVotes[i].name, false);
                        }
                    }
                }
            }
        }
    }

    function CheckIfVotingDone(Voting _Voting) internal returns(bool) {
        if ( (CalcDiff(_Voting.votesYes, _Voting.votesNo) > validatorsCount - (_Voting.votesYes + _Voting.votesNo)) 
            && (_Voting.timeStart + minimumVotingTime < now) ) {
            return true;
        } else {
            if (_Voting.timeStart + maximumVotingTime < now) {
                return true;
            } else {
                return false;
            }
        }
    }

    function CalcDiff(uint x, uint y) internal returns (uint) {
        if (x>y) {
            return x-y;
        } else {
            return y-x;
        }
    }

    function VotingResult(Voting _Voting) internal returns(bool) {
        if (_Voting.votesYes > _Voting.votesNo)
            return true;
        else
            return false;
    }
    //modifiers
    modifier onlyValidator() {
        if (IsValidator[msg.sender] == true) _;
    }

    modifier onlyNotValidator() {
        if ( !IsValidator[msg.sender] ) _;
    }
}