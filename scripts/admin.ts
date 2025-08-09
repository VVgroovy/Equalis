import { ethers } from "hardhat";

async function main() {
  const [admin] = await ethers.getSigners();
  const registryAddr = process.env.REGISTRY!;
  const payrollAddr = process.env.PAYROLL!;
  const employer = process.env.EMPLOYER!;

  const Registry = await ethers.getContractAt("EligibilityRegistry", registryAddr);
  const Payroll = await ethers.getContractAt("RedistributivePayroll", payrollAddr);

  // Grant attester to admin by default
  await (await Registry.setAttester(admin.address, true)).wait();

  // Register and grant eligibility for a sample address if provided
  const subject = process.env.SUBJECT;
  if (subject) {
    const identityId = ethers.id(subject.toLowerCase());
    await (await Registry.registerIdentity(subject, identityId)).wait();
    await (await Registry.grantEligibility(subject)).wait();
    console.log("Registered & granted:", subject, identityId);
  }

  if (employer) {
    await (await Payroll.setEmployer(employer, true)).wait();
    console.log("Employer granted:", employer);
  }
}

main().catch((e) => { console.error(e); process.exit(1); });


