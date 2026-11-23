provider "aws" {
  region = "eu-west-1"
}

variable "owner" {
  type        = string
  description = "Who owns the pet"
  default     = "student"
}

variable "name_length" {
  type        = number
  description = "Number of words in the pet name"
  default     = 2

  validation {
    condition     = var.name_length >= 1 && var.name_length <= 5
    error_message = "name_length must be between 1 and 5."
  }
}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Hello from Terraform"
}

resource "random_pet" "mascot" {
  length = var.name_length
  prefix = var.owner
}

locals {
  greeting = "Hello ${var.owner}, your pet is ${random_pet.mascot.id}"
}

resource "local_file" "greeting" {
  filename = "${path.module}/greeting.txt"
  content  = local.greeting
}

output "pet_name_new" {
  description = "The generated pet name"
  value       = random_pet.mascot.id
}

output "file_path_name" {
  description = "Where the greeting file was written"
  value       = local_file.greeting.filename
}