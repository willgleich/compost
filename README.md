# compost
*for dust thou art, and unto dust shalt thou return*
## Goals

The goals of the project are to create a compostable homelab extension in the cloud. Aiming for minimal configuration in order to connect local homelab to AWS and GCP.
Exploration has included NAT, Firewall and Routing modifications. Experimentation with "multi-cloud" in private network setting.

Current functionality:

* VPC/Subnet/Security Group terraform code
* SiteToSite VPN_Connection from local OPNsense to VPC in AWS and GCP
    * ansible script for OPNsense modification
    * NAT/Route options of onprem egress vs cloud NAT egress
* AWS EKS Installation and Configuration

