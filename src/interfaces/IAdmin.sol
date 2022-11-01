pragma solidity ^0.8.10;

interface IAdmin {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a new address is set for the Council
    event NewCouncil(address oldCouncil, address newCouncil);
    /// @notice Emited when a new address is set for the Founders
    event NewFounders(address oldFounders, address newFounders);
    /// @notice Emited when a new address is set for the Pauser
    event NewPauser(address oldPauser, address newPauser);
    /// @notice Emitted when pendingFounders is changed
    event NewPendingFounders(address oldPendingFounders, address newPendingFounders);

    ////////////////////
    ////// Errors //////
    ////////////////////

    /// @notice Error emitted when an auth condition is not met
    error Unauthorized();

    /////////////////////
    ////// Methods //////
    /////////////////////

    function acceptFounders() external;
    function council() external view returns (address);
    function executor() external view returns (address);
    function founders() external view returns (address);
    function pauser() external view returns (address);
    function pendingFounders() external view returns (address);
    function revokeFounders() external;
    function setCouncil(address _newCouncil) external;
    function setPauser(address _newPauser) external;
    function setPendingFounders(address _newPendingFounders) external;
}
