# CloudGaming on AWS
## Prerequisites
1. AWS Account with at least one IAM User with Admin Access to EC2 and access to S3
2. IAM Credentials (Access Key and Secret Access Key)
3. The following Account Quotas: EC2 G-Instances (both Spot and OnDemand) Requests >= 8
4. A VPC and subnet to launch your EC2 instances into 
5. A Security Group with the following inbound settings: RDP Port (TCP 3389) open to either 0.0.0.0 or just your IP, TCP Port 5900 (for VNC connections) open, TCP Ports 8000 - 8040 (for Parsec) open
6. A Parsec Account that you can register for [here](https://parsec.app/signup)
7. One or more games that need a proper gaming set up and that store Savegames in the cloud

## Setting up your primary instance
1. Create a g4dn instance (you can create a g4dn.xlarge for the initial setup and scale it up later to save money) with the following settings:
    1. Microsoft Windows Server 2019 Base AMI 
    2. Nothing to configure in "Instance Details" (you might have to create a VPN and Subnet if you don't already have them)
    3. In "Add Storage" resize your root drive to fit your games' needs - e.g. for Fallen Order I'd recommend about 90GB. Don't oversize it as this will cost money and make your Snapshot later on unnecessarily large
    4. Use the security group previously created
    5. Launch the instance
    
2. RDP into the instance, copy-paste the Powershell Scripts onto the instance and run part 1 of the scripts
3. Reboot
4. Run part 2 of the scripts
5. Install the games that you want to play in the cloud

## Setting up future Spot instances to save money
1. Create an image and snapshot from the instance that you have now set up and configured
2. Once you have tested your image, you can delete your primary instance
3. Every time you want to play from now on, just go to "AMIs" under "Images", right-click your AMI and launch a "Spot Request" with your desired specifications
