
const RocketTokenCrowdsale = artifacts.require("./RocketTokenCrowdsale.sol")
const RocketToken = artifacts.require("./RocketToken.sol")

module.exports = function(deployer, network, accounts) {
	var _admin = "0x0662a2f97833b9b120ed40d4e60ceec39c71ef18";
	var _team = "0x1EB5cc8E0825dfE322df4CA44ce8522981874d51";
	var _me = "0xe05416EAD6d997C8bC88A7AE55eC695c06693C58";
	var _investor = "0x458C56B50B3811780a3d650f20A0B5498B66E83b";

    //deploy the TigereumCrowdsale using the owner account
	return deployer.deploy(RocketTokenCrowdsale,
					  	accounts[0], 
					  	accounts[1], 
					  	accounts[2],
					  	accounts[3],
					  	{ from: accounts[1] }).then(function() {
		//log the address of the RocketTokenCrowdsale
  		console.log("RocketTokenCrowdsale address: " + RocketTokenCrowdsale.address);
      return RocketTokenCrowdsale.deployed().then(function(cs) {
  			return cs.token.call().then(function(tk) {
          console.log("Rocket token address: " + tk.address);
  			});
  		});
    });
};