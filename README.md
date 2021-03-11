# EKS Demo

Deploy an EKS cluster on AWS using Terraform! The [Terraform EKS](https://learn.hashicorp.com/tutorials/terraform/eks) tutorial from Hashicorp was used as a reference.

## Prerequisites

* [AWS CLI](https://aws.amazon.com/cli/) installed
    * Configured with access key
* [Terraform](https://www.terraform.io/downloads.html) installed
* Optional [kubectl](https://kubectl.docs.kubernetes.io/installation/kubectl/) installed


## Details

This demo is configured to deploy an EKS cluster on AWS, using a single worker node (configurable) as a `t2.small` EC2 instance.

As part of the demo, a service deployed called [Koncepts](https://github.com/smrowley/koncepts) that is used to demonstrate various K8s concepts. Container images of the application are hosted on [Docker Hub](https://hub.docker.com/r/srowley/koncepts).

As part of the Koncepts application, a `/timestamp` resource is exposed that will return JSON with a UNIX timestamp and configurable message:

```json
{
  "message": "Automate all the things!",
  "timestamp": 1615478556
}
```

The message is configurable via `TIMESTAMP_MESSAGE` environment variable in the container image.

## Installing the Cluster

```
terraform init

terraform apply
```

### Application Deployment

The terraform scripts also perform the application deployment for you. The resources are defined in `kubernetes.tf`. Koncepts is deployed with a K8s `Deployment` resource, and a K8s `Service` is configured as a `LoadBalancer` service. This creates an ELB in AWS that routes external requests to the application.

The URL can be retrieved with terraform outputs like so:

```
terraform output app_url
```

Or, you can request the `/timestamp` resource directly:

```
curl $(terraform output --raw app_url)/timestamp
```

## Kubernetes Interaction

You can set up your kube config using the outputs from terraform:

```
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
```

To switch namespaces to the application namespace:

```
kubectl config set-context --current --namespace $(terraform output -raw app_namespace)
```

Then you can view the current deployment or fetch the ELB URL from the service:

```
# view deployment
kubectl get deployment

# fetch ELB URL
kubectl get svc koncepts-demo-lb --template='{{"Hostname:\n"}}{{range.status.loadBalancer.ingress}}{{.hostname}}{{"\n"}}{{end}}'
```

## Cleanup

To destroy the cluster and application resources, run the following:

```
terraform destroy
```