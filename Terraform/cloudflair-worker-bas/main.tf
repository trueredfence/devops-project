# Terraform configuration for Cloudflare Worker deployment
# Terraform version: ~> 5.0

terraform {
  required_version = ">= 1.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Variables
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare Zone ID (optional, for custom domain routing)"
  type        = string
  default     = ""
}

variable "worker_name" {
  description = "Name of the Cloudflare Worker"
  type        = string
  default     = "reverse-proxy-worker"
}

variable "backend_api_url" {
  description = "Backend API URL to proxy to"
  type        = string
}

variable "rate_limit" {
  description = "Rate limit per minute per IP"
  type        = number
  default     = 100
}

variable "worker_subdomain" {
  description = "Custom subdomain for worker (e.g., api.yourdomain.com)"
  type        = string
  default     = ""
}

variable "enable_kv_rate_limiting" {
  description = "Enable persistent rate limiting with KV"
  type        = bool
  default     = false
}

variable "workers_dev_subdomain" {
  description = "Your workers.dev subdomain (e.g., 'redfencehunter')"
  type        = string
  default     = ""
}

variable "use_random_subdomain" {
  description = "Use random string for subdomain instead of worker name"
  type        = bool
  default     = true
}

variable "random_subdomain_length" {
  description = "Length of random subdomain string"
  type        = number
  default     = 16
}

# Provider configuration
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Generate random subdomain
resource "random_string" "subdomain" {
  count   = var.use_random_subdomain ? 1 : 0
  length  = var.random_subdomain_length
  special = false
  upper   = false
  numeric = true
  lower   = true
}

# Local variable for final subdomain name
locals {
  subdomain_name = var.use_random_subdomain ? random_string.subdomain[0].result : var.worker_name
}

# Read and modify worker.js file
locals {
  worker_script = replace(
    replace(
      file("${path.module}/worker.js"),
      "const BACKEND_API_URL = env.BACKEND_API_URL || 'https://your-backend-api.com';",
      "const BACKEND_API_URL = env.BACKEND_API_URL || '${var.backend_api_url}';"
    ),
    "const RATE_LIMIT = 100;",
    "const RATE_LIMIT = ${var.rate_limit};"
  )
}

# KV Namespace for persistent rate limiting (optional)
resource "cloudflare_workers_kv_namespace" "rate_limit_kv" {
  count      = var.enable_kv_rate_limiting ? 1 : 0
  account_id = var.cloudflare_account_id
  title      = "${var.worker_name}-rate-limit"
}

# Worker Script
resource "cloudflare_workers_script" "reverse_proxy" {
  account_id  = var.cloudflare_account_id
  script_name = local.subdomain_name
  content     = local.worker_script
  main_module = "worker.js"

  # Bindings for KV namespace (if enabled)
  bindings = var.enable_kv_rate_limiting ? [
    {
      type         = "kv_namespace"
      name         = "RATE_LIMIT_KV"
      namespace_id = cloudflare_workers_kv_namespace.rate_limit_kv[0].id
    }
  ] : []

  compatibility_date  = "2024-01-01"
  compatibility_flags = ["nodejs_compat"]
  logpush             = false
}

# Enable workers.dev subdomain
resource "cloudflare_workers_script_subdomain" "reverse_proxy_subdomain" {
  account_id       = var.cloudflare_account_id
  script_name      = cloudflare_workers_script.reverse_proxy.script_name
  enabled          = true
  previews_enabled = true
}

# Worker Route (if custom domain is provided)
resource "cloudflare_workers_route" "reverse_proxy_route" {
  count   = var.zone_id != "" && var.worker_subdomain != "" ? 1 : 0
  zone_id = var.zone_id
  pattern = "${var.worker_subdomain}/*"
  script  = cloudflare_workers_script.reverse_proxy.script_name
}

# Custom Domain DNS Record
resource "cloudflare_dns_record" "worker_domain" {
  count   = var.worker_subdomain != "" && var.zone_id != "" ? 1 : 0
  zone_id = var.zone_id
  name    = var.worker_subdomain
  content = "${local.subdomain_name}.${var.cloudflare_account_id}.workers.dev"
  type    = "CNAME"
  ttl     = 1 # 1 means automatic (proxied)
  proxied = true
  comment = "Managed by Terraform - Worker proxy"
}

# Outputs
output "worker_url" {
  description = "Worker URL (workers.dev subdomain)"
  value       = var.workers_dev_subdomain != "" ? "https://${local.subdomain_name}.${var.workers_dev_subdomain}.workers.dev" : "https://${var.worker_name}.${var.cloudflare_account_id}.workers.dev (Set workers_dev_subdomain variable for correct URL)"
}

output "preview_url_pattern" {
  description = "Preview URL pattern"
  value       = var.workers_dev_subdomain != "" ? "https://*-${local.subdomain_name}.${var.workers_dev_subdomain}.workers.dev" : "Not available - set workers_dev_subdomain variable"
}

output "random_subdomain" {
  description = "Generated random subdomain (if enabled)"
  value       = var.use_random_subdomain ? random_string.subdomain[0].result : "Not using random subdomain"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.worker_subdomain != "" ? "https://${var.worker_subdomain}" : "Not configured"
}

output "worker_name" {
  description = "Deployed worker name"
  value       = cloudflare_workers_script.reverse_proxy.script_name
}

output "kv_namespace_id" {
  description = "KV namespace ID for rate limiting"
  value       = var.enable_kv_rate_limiting ? cloudflare_workers_kv_namespace.rate_limit_kv[0].id : "Not enabled"
}
