# Terraform Remote State setup

Generates the necessary infrastructure and permissions to manage the Terraform state remotely. This creates an AWS s3 bucket to store the state and a DynamoDB to lock it. It also restricts the permissions of each of these elements, by applying the appropriate policies. This module can be used upon the creation of other more complex projects, to setup the remote state. This module can be found at the terraform regristry: [terraform-aws-remote-state](https://registry.terraform.io/modules/rafaelmarques7/remote-state/aws/1.1.0).
<hr />


## Table of contents
- [Terraform Remote State setup](#terraform-remote-state-setup)
  - [Table of contents](#table-of-contents)
  - [Folder structure](#folder-structure)
  - [Deployment](#deployment)
  - [WWH - what, why, how](#wwh---what-why-how)
  - [Input arguments](#input-arguments)
  - [Output](#output)
  - [Security](#security)
  - [Common Problems](#common-problems)
  - [Reading material](#reading-material)
<hr />


## Folder structure
```
remote_state
  ├── main.tf             | remote state setup
  ├── outputs.tf          | provided output
  ├── variables.tf        | input arguments 
  └── README.md           | this file 
```
<hr />


## Deployment
1. Generate and set the required [input arguments](#input-arguments).

```
export ACCOUNT_ID=$DEV_ID && \
export AWS_PROFILE=$AWS_PROFILE_NAME && \
export LIST_ACCOUNTS=["\"$DEV_ID"\"] && \
export BUCKET_NAME="remote-state-bucket-"$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1) && \
export DYNAMODB_TABLE_NAME="dynamodb-state-lock-"$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1)
```

Notes: 
* Run the above procedure only once! 
  * The S3 bucket has a lifecycle protection rule. 
  * Every time this is run, a new bucket and dynamodb table name is created. 
  * Thus, upon running terraform for a 2nd time, it will raise an error, because the state (and, in particular, the bucket reference) is different.

2. Run terraform with the required input.
```bash
terraform init && \
terraform apply \
--var account_id=$ACCOUNT_ID \
--var bucket_name=$BUCKET_NAME \
--var aws_access_key=$AWS_ACCESS_KEY \
--var aws_secret_key=$AWS_SECRET_KEY \
--var list_account_ids=$LIST_ACCOUNTS \
--var dynamodb_table_name=$DYNAMODB_TABLE_NAME \
-auto-approve 
```

3. Output should be something like this:
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

* s3_bucket_domain_name
* s3_bucket_id
* dynamodb_table_id
```

<hr />



## WWH - what, why, how
**What?** This is a terraform script to automate the process of deploying the necessary infrastructure to manage Terraform state remotely. It can be **used to setup any Terraform project**.

**Why?** If you are using Terraform by yourself, managing state locally might be enough. However, when working in teams, different team members must have the same infrastructure representation (state!). If this is not the case, and each member of the team has the state stored locally, the infrastructure will break easily, because **a change made by one person will not propagate to the others**. The way to overcome this is using [remote state](https://www.terraform.io/docs/providers/terraform/d/remote_state.html).  

**How?** The remote state will be stored in AWS S3. A bucket is created, and the state file is stored there. As to guarantee that the state is only accessed by one person at a time, a DynamoDb table is used to lock it. The bucket and table have limited permissions.

 **In summary: &nbsp;  s3 bucket +++ dynamodb table +++ permissions**.
<hr />


## Input arguments

List of input arguments:

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| account\_id | The ID number of the account to where the state is being deployed. | string | - | yes |
| aws-profile | The AWS profile name. | string | - | yes |
| aws-region | The AWS region where the terraform stack is created | string | `eu-west-1` | no |
| bucket\_name | The name for the bucket where the remote state is saved. | string | - | yes |
| dynamodb\_table\_name | The name of the DynamoDb table used to lock the state. | string | - | yes |
| list\_account\_ids | A list containing IDs of account that may access the state. | list | - | yes |
| remote\_state\_file\_name | The name for the file where the remote state is saved | string | `state_terraform` | no |

<hr />


## Output 

List of output variables:

| Name | Description |
|------|-------------|
| dynamodb-table-id | The DynamoDB table ID. |
| s3-bucket-domain-name | The state bucket domain name. |
| s3-bucket-id | The state bucket ID. |

<hr />


## Security
* This script deploys an s3 bucket and dynamodb table with an identity-based policy. 
* **It gives access to all accounts listed in $LIST_ACCOUNT_IDS.**
* This is not the safest option out there.

Why did we opt for this, instead of locking the access to a **single** user?

Consider this scenario:
  * you use this module (with the single user functionality) and deploy a remote state;
  * now you want to create a new and bigger project (a); 
  * you use this module as the base to create the state for (a);
  * you deploy (a) using the reffered user;
  * the deployment tries to access some AWS resource, like CloudFormation;
  * you get an error stating **permissions denied**;
  * you go back and give this user the required extra permissions;
  * you would do this for every project, always changing the source code related to the user inside this module.

If, eventually, we really want to use an user for single access, we should create it separately, and receive its information as an input argument.
<hr />


## Common Problems
Please note that:
  * running this script multiple times will cause unexpected errors.
    * this happens because the resources already exist, there is conflict in the state, or for some other reason.
  * this script should be executed once and once only.
  * if that execution fail, you should delete all the resources created previous to the failure, and retry.
<hr />


## Reading material
Here is some useful reading material (for multiple purposes):

* [why this is necessary](https://stackoverflow.com/questions/47913041/initial-setup-of-terraform-backend-using-terraform)
* [official terraform remote state docs](https://www.terraform.io/docs/state/remote.html)
* [terraform **conventions**](https://github.com/jonbrouse/terraform-style-guide/blob/master/README.md)
* [policies: identity-based vs resource-based](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html)
* [terraform S3 bucket](https://www.terraform.io/docs/providers/aws/r/s3_bucket.html) and [bucket object](https://www.terraform.io/docs/providers/aws/r/s3_bucket_object.html)
* [terraform dynamodb_table](https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html)
* [policies with terraform - **guide**](https://www.terraform.io/docs/providers/aws/guides/iam-policy-documents.html)
* [terraform policy **Document**](https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html), [policy **Attachment**](https://www.terraform.io/docs/providers/aws/r/iam_policy_attachment.html), [iam **Policy**](https://www.terraform.io/docs/providers/aws/r/iam_policy.html)
* [publish modules to terraform registry](https://www.terraform.io/docs/registry/modules/publish.html) and [standard module structure](https://www.terraform.io/docs/modules/create.html#standard-module-structure)
* [S3 backend config](https://www.terraform.io/docs/backends/types/s3.html)
<hr />
