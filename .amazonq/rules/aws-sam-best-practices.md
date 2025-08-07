# Project Rules – AWS SAM Best Practices

## 1. Structure and Organization
- All infrastructure resources must be defined using AWS SAM templates (`template.yaml`) following clear naming conventions.
- Lambda functions must use a consistent naming pattern like `Function[Purpose]`, e.g., `FunctionUserSignup`.
- Use `Globals` and `Parameters` in the SAM template to avoid duplication and promote reuse.

## 2. Security
- All S3 buckets must have server-side encryption enabled and public access blocked.
- DynamoDB tables must have encryption at rest and proper read/write access controls.
- Secrets (e.g., API keys, JWTs) must be stored in **AWS Secrets Manager** or **SSM Parameter Store** — never hardcoded.

## 3. Infrastructure as Code (IaC)
- Templates must follow SAM structure with minimal conditional logic.
- Use `Transform: AWS::Serverless-2016-10-31` at the top of every SAM template.
- Prefer **nested applications** for reusable components to encourage modularity and code sharing.

## 4. Code Quality and Amazon Q Expectations
- Amazon Q must follow these rules and validate security when generating code.
- All generated functions must include appropriate docstrings (Python) or Javadoc (Java).
- Prompts to Amazon Q should include SAM context such as runtime, timeout, memory size, VPC settings, and events.

## 5. Testing and Validation
- Templates must support local testing via **SAM CLI** (`sam local invoke`, `sam local start-api`).
- Unit tests must be included using frameworks like `pytest` (Python), with mocking tools like `moto` or **AWS Powertools**.
- Tests must cover input validation, edge cases, and error handling.

## 6. CI/CD and Deployment
- A CI/CD pipeline (e.g., GitHub Actions, AWS CodePipeline) must:
  - Run linter and validate `template.yaml`
  - Build and deploy via `sam build` and `sam deploy`
  - Run automated tests and security checks
- Amazon Q may suggest CI/CD pipelines if the prompt includes deployment context.

## 7. Observability and Operations
- Lambda functions must use **AWS Powertools** for structured logging, metrics, and tracing.
- IAM permissions must follow the **principle of least privilege**.
- CloudWatch alarms and dashboards must be configured for metrics like errors, latency, and invocations.

## 8. Prompting and Context Usage with Amazon Q
- When prompting Amazon Q:
  - Specify the programming language (e.g., Python, Java).
  - Include detailed SAM requirements (runtime, memory, events, etc.).
  - Use Markdown or code output formatting where needed.
  - Use `@workspace` to enable full context awareness across your repo.
