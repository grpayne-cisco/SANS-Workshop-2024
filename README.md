# SANS CloudSecNext Summit 2024 - Workshop

## Prerequisites 
**Required**
* Github.com Account
* Installed locally: git
* IDE / Code Editor

**Optional**
* Installed locally: Docker/Docker Compose OR Podman/Podman Compose
* Installed locally: Conftest
* Installed locally: Terraform

##  Debugging with GitHub Actions
In our simulated scenario, GitHub actions is our CI tool and also provides the gating for our OPA rules. It runs a containerized environment that executes the terraform plans and OPA validations. Using this we can both gate our work flow as well as test our changes without the need for specific tooling on our local machine.

We will walkthrough this process in the [Setup](#setup) and [Exercise 1 - Github Actions and a Failing Pipeline](#exercise-1---github-actions-and-a-failing-pipeline)

## Local Debugging
If you want to debug on your local machine, instead of just leveraging  github actions, there are two options:
* (Recommended) [Use the simulated containerized environment](demo-env/README.md)
* [Setup the each of the tools on your machine and connect to an AWS account](local-debugginf.md)

### Creating terraform output files
_Note: If you are running locally against a real AWS account replace tflocal with terraform_
1. Enter the terraform directory containing the terraform you are working with, for example run: ```cd /workspace/terraform/rds``` or ```cd /workspace/terraform/s3```
2. Run ```tflocal init``` to initialize terraform. _If you are familar with terraform you will notice we are using tflocal instead of terraform. This is to leverage localstack to simulate our AWS account_
3. Run ```tflocal plan --out tfplan.binary``` to create a plan for the terraform file and output it as a binary.
4. Run ```tflocal show -json tfplan.binary > tfplan.json``` to generate the json terraform output the we will evaluate with OPA.


### Options to formatting the json output:
The output of the tflocal/terraform show will not have whitepace formatting, making it hard to read, you can use one of the following options to format the code:
- IDEs like VSCode you can right click and select Format and the document will be formatted
- If you have jq installed you can run: ```jq . tfplan.json > tfplan-pretty.json```
- You can paste the JSON into this website and have it formatted for you (in a real world scenario the terraform output could have sensitive data in it and this is not recommended): https://jsonformatter.org/

### Evaluating our terraform plan output
We use conftest to evaluate our terraform output against our policies.

From the folder where the terraform output was created, run: 
* For JSON output: ```conftest test --all-namespaces -p /workspace/policies tfplan.json --output json```

It will output if the policies that are written are successful or fail.

Example:
```json
[
        {
                "filename": "tfplan.json",
                "namespace": "aws.validation",
                "successes": 1,
                "failures": [
                        {
                                "msg": "RDS should not specify passwords",
                                "metadata": {
                                        "details": {
                                                "rds_with_password": [
                                                        "my_db"
                                                ]
                                        }
                                }
                        }
                ]
        }
]
```

## Reference Materials
- [OPA Overview](https://www.openpolicyagent.org/docs/latest/#rego)
- [OPA Language Reference](https://www.openpolicyagent.org/docs/latest/policy-reference/)
- [OPA Cheat Sheet](https://docs.styra.com/opa/rego-cheat-sheet)

## Workshop

We will do the [Setup](#setup), [Review the Pipeline](#review-the-pipeline), [Review an OPA Policy](#review-an-opa-policy) and [Exercise 1](#exercise-1---github-actions-and-a-failing-pipeline) as a group. The remainder will be done independently.

### Setup
1. Fork the repo into your own account (this will allow you to use the github runners)
2. Checkout the repo to your local machine
3. Create a branch work from
4. Open your code in you preferred IDE

### Review the pipeline
Github actions defines it's pipeline in .github/workflows/ci.yml. Lets take a look at the steps it performs to do validation of the planned Terraform.

### Review an OPA Policy
There is already two OPA Policy created in:
* policies/pass.rego - this is a stripped down policy that always passes
* policies/rds/password.rego - this policy ensures a plaintext password is not set for the database


### Exercise 1 - Github Actions and a Failing Pipeline
In this exercise we want to trigger Github Actions to run our OPA checks, see them pass and also see them fail. Then we want to correct our code to get the pipeline to pass.
1. Add a line to the bottom of this README.md
2. Commit and Push the change.
3. Create a pull request for the branch
4. Open the repo in a browser and browse to your PR
5. Open the link to the failing action _Run OPA Tests - rds_
6. Under the failing Validate OPA step expand the Testing 'tfplan.json' against 2 policies in namespace 'aws.validation' section. What is the error?
7. Open the terraform for the RDS in terraform/rds/main.tf and fix the problem
8. Commit and push the code
9. The OPA checks should succeed now.

<details>
<summary>Hint</summary>
The fix is commented out in terraform/rds/main.tf.
</details>

### Exercise 2 - Enforce Encryption of RDS
In this exercise we want to ensure our databases are encrypted.
1. Open the terraform/rds/main.tf files. You should see that storage encryption (```storage_encrypted```) is disabled
2. If you have your local environment setup you can run the steps to generate the plan outputs with ```storage_encrypted``` set to true and false. Otherwise the plan files are in testfiles/aws/rds/encryption
3. Evaluate the difference in the plan outputs. 
4. Write a policy in the policies/rds folder

_Bonus_ - In terraform if a parameter is not required, it will have a default value if it is not specified. In the case of ```storage_encrypted``` encryption the default value is false. Remove the ```storage_encrypted``` parameter and redo the plan (or look in testfiles/aws/rds/encryption/not-set). How does this compare to the other plan outputs? Will your policy need to be updated to cover this case?

### Exercise 3 - Enforce Tagging Resources
In this exercise we want to ensure all our resources have proper tags.
1. Open the terraform/rds/main.tf and the terraform/s3/main.tf files. You should see the lines commented out to enable tagging.
2. If you have your local environment setup you can run the steps to generate the plan outputs with and without tagging enabled. Otherwise the plan files are in testfiles/aws/s3/tagging and testfiles/aws/rds/tagging
3. Evaluate the difference in the plan outputs. 
4. Write a policy in the policies folder that requires a data_classification and owner_email tag.

<details>
<summary>Hint</summary>

Undefined or null references will cause the expression block to halt and ext immediately. If you have checks for null, break them up into multiple expressions, wrap in functions, or use a combination of ```is_object(resource)``` and  ```contains_element(object.keys(resource), "KEY")```
</details>
<p>

_Bonus_ - Have you validated the tagging values? Making sure people are providing good data is important for resource tagging. Ensure that the values are constrained to:
* data_classification is either public or private
* owner_email is a valid email address. 

<details>
<summary>Hint</summary>
Rego supports regex expressions to do the email validation: https://docs.styra.com/opa/rego-by-example/builtins/regex
</details>
<p>

_Bonus_ - Some AWS resources do not support tags, for example [Security Hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account). What will happen when your policy evaluates the terraform plan for Security Hub? You can uncomment out the terraform for Security Hub in terraform/securityhub and run an plan (or look in testfiles/aws/securityhub). Will your policy need to be updated to cover this case?

### Exercise 4 - Put in Exception Case Encryption of Databases
In the exercise 2 we ensured our RDS instances were encrypted, but that may not always be required, for example if we are storing public data. We will put in an exception to the encryption requirement if someone has tagged their RDS instance as public.
1. Open the terraform/rds/main.tf files.
2. Locate the data_classification tag.
2. If you have your local environment setup you can run the steps to generate the plan outputs with data_classification set to public and private. Otherwise the plan files are in testfiles/aws/rds/exception_for_encryption
3. Evaluate the difference in the plan outputs. 
4. Update the policy in the policies/rds folder that you wrote in Exercise 3

<details>
<summary>Hint</summary>

You can chain multiple checks together on multiple lines (in a rule body), and they evaluate with and.
</details>
<p>
<details>
<summary>Hint 2</summary>

There is no intrinsic or in rego, but if you have 2 boolean expressions that are assigned to the same value they will use an or for the assignment. [How to express OR in Rego](https://www.styra.com/blog/how-to-express-or-in-rego/)
</details>
<p>
<details>
<summary>Hint 3</summary>

If you need to nest an and within an or, try putting use a function to wrap the and statement [Functions](https://www.openpolicyagent.org/docs/latest/policy-language/#functions)
</details>
<p>
<details>
<summary>Hint 4</summary>

If you want a function to have a default value if the evaluation fails, you can add a default value, like  ``` funcName(args) if { LOGIC} else := false```
</details>

### Bonus
By default new buckets don't allow public access. We can use the terraform resource [s3_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/3.24.1/docs/resources/s3_bucket_public_access_block) to allow a bucket to be public (also plan is in testfiles/aws/s3/allow-public).

Can you put a restriction in that enforces that a bucket being made public, is also tagged as public? Update the terraform, run some plans and see.

## From Here

Repository Setup:
* This is just a sample project. Typically the OPA Policies and the terraform would live in separate repositories so the policies can be shared across multiple terraform repos.

Things to think about:
* Warn vs deny
* Better messaging for errors

Links: 

## Questions
* Why do we do we evaluate the plan vs the terraform directly? Although our examples are very simple, terraform can get complex with levels of indirection through the use of multiple files and modules. The plan is the evaluation of all that combine and gives us a single file for evaluation.
* My trace statements are not printing, why? Make sure you are not specifying an output, like ```--output json```, since this will suppress printed messages or trace statements.
* My tests are passing when they should fail, why? OPA evaluation will silently fail if it gets a null reference. Try using a print statement (```print(<VARIABLE>```)) of what you are evaluating to see what is being checked.
