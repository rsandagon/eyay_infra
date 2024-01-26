
# AWS
1. user `rsandagon_admin` in IAM [Identity Center](https://d-9067f56e63.awsapps.com/start) 
1. export AWS credentials `export AWS_ACCESS_KEY_ID=` and `export AWS_SECRET_ACCESS_KEY=`
1. run `terraform init` to initialize tf
1. run `terraform plan` to see changes
1. run `terraform fmt` to format terraform files
1. run `terraform show` to see infra state 
1. run `terraform apply` to apply infra changes 

# ENV VAR
1. Get `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` [here](https://us-east-1.console.aws.amazon.com/iam/home#/users/details/rsandagon_admin/create-access-key)

# References
* https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build