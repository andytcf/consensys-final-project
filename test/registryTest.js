const ResidentialHome = artifacts.require("ResidentialHome");

contract("ResidentialHome", async (accounts) => {
  it("Testing ResidentialHome", async () => {
    instance = await ResidentialHome.new(
      "inputted_address",
      "_zip",
      "_city",
      "_country",
      {
        from: accounts[0],
      }
    );
  });
});
