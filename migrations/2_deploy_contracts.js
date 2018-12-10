var SimpleStorage = artifacts.require("./SimpleStorage.sol");
var Splitter = artifacts.require("./Splitter.sol");

module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(Splitter);
};
