# Infrastructure as Code NanoDegree Project  
![aws logo](https://user-images.githubusercontent.com/48868321/184529873-ab254a43-edb8-4afb-bf33-f3f6e3521463.png ) ![image](https://user-images.githubusercontent.com/48868321/184529926-42070e44-6708-4660-b39b-181a114b03e2.png)



This project is about deploying a high-availability web server using CloudFormation.
AWS CloudFormation is a service that helps you model and set up your AWS resources so that you can spend less time managing those resources and more time focusing on your applications that run in AWS. You create a template that describes all the AWS resources that you want (like Amazon EC2 instances or Amazon RDS DB instances), and CloudFormation takes care of provisioning and configuring those resources for you.
When you provision your infrastructure with CloudFormation, the CloudFormation template describes exactly what resources are provisioned and their settings. Because these templates are text files, you simply track differences in your templates to track changes to your infrastructure, similar to the way developers control revisions to source code. For example, you can use a version control system with your templates so that you know exactly what changes were made, who made them, and when. If at any point you need to reverse changes to your infrastructure, you can use a previous version of your template.

The resources created by this stack includes:
* Virtual Private Cloud (VPC) - A virtual private cloud (VPC) is a virtual network dedicated to your AWS account. It is logically isolated from other virtual networks in the AWS Cloud. You can specify an IP address range for the VPC, add subnets, add gateways, and associate security groups. Amazon Virtual Private Cloud (Amazon VPC) enables you to launch AWS resources into a virtual network that you've defined. This virtual network closely resembles a traditional network that you'd operate in your own data center, with the benefits of using the scalable infrastructure of AWS.

* Subnets - A subnet is a range of IP addresses in your VPC. You launch AWS resources, such as Amazon EC2 instances, into your subnets. You can connect a subnet to the internet, other VPCs, and your own data centers, and route traffic to and from your subnets using route tables.

* Internet Gateway - An internet gateway is a horizontally scaled, redundant, and highly available VPC component that allows communication between your VPC and the internet. It supports IPv4 and IPv6 traffic. It does not cause availability risks or bandwidth constraints on your network traffic.

  An internet gateway enables resources in your public subnets (such as EC2 instances) to connect to the internet if the resource has a public IPv4 address or an     IPv6 address. Similarly, resources on the internet can initiate a connection to resources in your subnet using the public IPv4 address or IPv6 address. For         example, an internet gateway enables you to connect to an EC2 instance in AWS using your local computer.

* Application Load Balancer - Elastic Load Balancing automatically distributes your incoming traffic across multiple targets, such as EC2 instances, containers, and IP addresses, in one or more Availability Zones. It monitors the health of its registered targets, and routes traffic only to the healthy targets. Elastic Load Balancing scales your load balancer as your incoming traffic changes over time. It can automatically scale to the vast majority of workloads.

  Elastic Load Balancing supports the following load balancers: Application Load Balancers, Network Load Balancers, Gateway Load Balancers, and Classic Load           Balancers. You can select the type of load balancer that best suits your needs. 

* Route Tables - A route table contains a set of rules, called routes, that determine where network traffic from your subnet or gateway is directed.

* Auto Scaling Group - An Auto Scaling group contains a collection of EC2 instances that are treated as a logical grouping for the purposes of automatic scaling and management. An Auto Scaling group also enables you to use Amazon EC2 Auto Scaling features such as health check replacements and scaling policies.

* IAM Policy - IAM policies define permissions for an action regardless of the method that you use to perform the operation. For example, if a policy allows the GetUser action, then a user with that policy can get user information from the AWS Management Console, the AWS CLI, or the AWS API.

* Network address Translation (NAT) - It provides a way for servers/instances in the private subnet to access the Internet, for example, servers downloading the software or security patches. NAT Gateway keeps the private instances protected from unsolicited inbound connections from the Internet. To provide outbound internet access to resources in the private subnets, we configure the NAT gateway to route the outbound requests to the Internet gateway for the VPC. While routing the outbound requests, the NAT gateway replaces the source instances' (private) IP address with NAT's own (public) IP address.
  When sending the "response" traffic back to the instances, the NAT gateway translates the addresses back to the original source IP address, meaning it "translates" the incoming response into private traffic.
   

## Infrastructure Diagram 
Diagrams are a very important starting point for planning your cloud infrastructure. DevOps engineers start with a visual representation of the required cloud infrastructure before they turn it into code.
In this project, I made use of www.lucidchart.com to draw the diagram.



![image](https://user-images.githubusercontent.com/48868321/184529491-1235cd51-b116-4538-808f-0a9d6dcf04e3.png)


