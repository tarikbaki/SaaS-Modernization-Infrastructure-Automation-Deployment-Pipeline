# SaaS Infrastructure Automation & Deployment

## Business Impact

This project enables SaaS companies to accelerate **time-to-market** by providing an automated, secure, and scalable AWS infrastructure.  
Key business benefits:  
- **Faster onboarding & releases**: GitHub Actions pipeline shortens deployment cycles from days to minutes.  
- **Reduced operational risk**: Rollback and multi-AZ design minimize downtime and service disruption.  
- **Cost control**: NAT, auto-scaling ready subnets, and least-privilege IAM ensure optimized spend without sacrificing reliability.  
- **Compliance & security by design**: TLS (443), secret management via AWS SSM/Secrets Manager, and IAM roles align with SaaS security standards (ISO, PCI-DSS readiness).  
- **Customer trust**: High availability and secure deployments improve end-user confidence and SLA adherence.  


🔗 [Architecture Proposal](https://docs.google.com/presentation/d/1_nGMZ7gd_cZ0r2seUki0nRM0GeFvYzW3K8TZHIvS33E/edit?usp=sharing)

![alt text](image.png)

🔗 [Architecture Diagram (Miro Embed)](https://miro.com/app/live-embed/uXjVJR_35HQ=/?embedMode=view_only_without_ui&moveToViewport=-1247%2C-497%2C967%2C458&embedId=715496053132)

🔗 [Miro Board Link](https://miro.com/welcomeonboard/dzBvTmxpak1tRmNVamo4eHBiaFZhelNjb2MxQlZEVkZXM25YdVJmZkRPZHd6U2dJdFR5YTFkekxpK0tmOWFTRWd0N2szeHlZNjlSK25UdzlaQTFLZmFmay9RbWkyS052OUVYcjRkTGNBbzNiZUhtT2JWcmNveXN1WlJGelNtTi90R2lncW1vRmFBVnlLcVJzTmdFdlNRPT0hdjE=?share_link_id=342912202277)

---

## Overview
This repository contains **Terraform IaC** and a **GitHub Actions pipeline** to provision and deploy a SaaS application on AWS in a secure, automated, and scalable way.

---

## Infrastructure
- **VPC**: 2 public + 2 private subnets, Internet Gateway, NAT Gateway, route tables  
- **Security Groups**: least privilege (ALB open on 80/443, EC2 only from ALB SG)  
- **EC2 instances**: staging + production (deployed into private subnets)  
- **Application Load Balancer (ALB)**:
  - Default → Production Target Group  
  - Path rule `/staging*` → Staging Target Group  
- **IAM**: EC2 Instance Role with SSM + ECR ReadOnly policies  
- **ECR**: container image repository  
- **SSM Parameter Store**: keeps current image tag for staging and production  

### Project Structure

```bash
saas-modernization-infra-v3-prod/
├─ infra/
│  ├─ provider.tf                 # TF & AWS provider
│  ├─ variables.tf                # name, aws_region, vpc_cidr, ami, instance_type
│  ├─ main.tf                     # VPC(2 pub+2 priv), IGW, NAT, RTs
│  │                              # SGs(ALB, EC2), ALB+TG+listener+rule(/staging)
│  │                              # IAM(EC2 role+SSM+ECR), ECR repo, SSM params
│  │                              # EC2: staging+prod (private subnets)
│  └─ outputs.tf                  # alb_dns, ecr_repo_url
│
├─ .github/
│  └─ workflows/
│     └─ ci-cd.yml                # OIDC auth → ECR push → SSM deploy (stg/prod) → rollback
│
├─ app/
│  ├─ Dockerfile                  # nginx base image
│  └─ index.html                  # static placeholder
│
└─ README.md                      # setup, secrets, deploy/rollback, security notes
```

Terraform code is under `/infra`.

---

## CI/CD Pipeline
- **Authentication**: GitHub → AWS via **OIDC role assumption** (no static keys)  
- **Build & Test**: on every push  
- **Docker Build & Push**: tag image with commit SHA + `latest`, push to ECR  
- **Deploy to Staging**: on `develop` branch → update SSM param + redeploy EC2 via RunCommand  
- **Deploy to Production**: on `main` branch → update SSM param + redeploy EC2 via RunCommand  
- **Rollback Job**: reverts to previous image tag from SSM Parameter Store if deploy fails  

Pipeline config is under `.github/workflows/ci-cd.yml`.

---

## Secrets Management
- All **sensitive data** in **AWS SSM Parameter Store** or **AWS Secrets Manager**  
- **GitHub Secrets** used for OIDC role ARN & repo info (no static credentials)  
- No plaintext secrets in repo  

---

## Deployment
```bash
cd infra
terraform init
terraform apply -var="name=saas" -var="aws_region=us-east-1"
