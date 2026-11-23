# =============================================================================
# META-ARGUMENTS IN TERRAFORM
# =============================================================================
# A META-ARGUMENT is a special argument built into TERRAFORM ITSELF (not into a
# provider). It changes HOW Terraform handles a resource, so it works on any
# resource, whichever provider it comes from.
#
#   Normal arguments : WHAT the resource is   (filename, content, length ...)
#                      -> defined by the PROVIDER, different per resource
#   Meta-arguments   : HOW Terraform handles it (count, for_each ...)
#                      -> defined by TERRAFORM, same on every resource
#
#   +--------------+-------------------------------------------------------+
#   | depends_on   | force an explicit creation ORDER                      |
#   | count        | create N copies by NUMBER                             |
#   | for_each     | create one copy per ITEM of a set or map              |
#   | provider     | choose WHICH provider configuration (alias) to use    |
#   | lifecycle    | control create / update / destroy behavior            |
#   +--------------+-------------------------------------------------------+
#
# RULES
#   - count and for_each can NOT be used together on the same resource.
#   - Their values must be known at PLAN time.
#   - Prefer implicit dependencies (references) over depends_on.
#
# HOW TO RUN (put this file in its own empty folder)
#   terraform init
#   terraform plan
#   terraform apply
#   terraform output
#   terraform destroy
#
# Files are created in ./generated/  (add "generated/" to .gitignore)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# -----------------------------------------------------------------------------
# VARIABLES (inputs used by the examples below)
# -----------------------------------------------------------------------------
variable "pet_count" {
  type        = number
  description = "How many pets to create with count"
  default     = 3
}

variable "owners" {
  type        = set(string)
  description = "A SET of owner names, used with for_each"
  default     = ["alice", "bob"]
}

variable "pet_types" {
  type        = map(string)
  description = "A MAP of owner => animal, used with for_each"
  default = {
    alice = "dog"
    bob   = "cat"
    carol = "rabbit"
  }
}

variable "create_extra" {
  type        = bool
  description = "Switch: create the optional file or not"
  default     = true
}


# =============================================================================
# 1. depends_on : EXPLICIT dependency
# =============================================================================
# Terraform normally finds the order by itself from REFERENCES (implicit
# dependency). Use depends_on only when there is NO reference between two
# resources but one must still wait for the other.
#
#   local_file.config  ..depends_on..>  random_pet.after_config
#   (created FIRST)                     (created SECOND)
#
# Without depends_on, these two would be created IN PARALLEL because
# random_pet.after_config never uses a value from local_file.config.
# -----------------------------------------------------------------------------
resource "local_file" "config" {
  filename = "${path.module}/generated/config.txt"
  content  = "config is ready"
}

resource "random_pet" "after_config" {
  length = 2

  depends_on = [local_file.config] # wait until the file exists
}


# =============================================================================
# 2. count : create N copies by NUMBER
# =============================================================================
# count.index is the position: 0, 1, 2 ...
# Instances are addressed by INDEX:  random_pet.counted[0], [1], [2]
#
#   random_pet.counted[0] --> local_file.counted[0] --> count-0.txt
#   random_pet.counted[1] --> local_file.counted[1] --> count-1.txt
#   random_pet.counted[2] --> local_file.counted[2] --> count-2.txt
#
# CAUTION: removing an item from the MIDDLE shifts the indexes after it, which
# can make Terraform destroy and recreate the later items.
# -----------------------------------------------------------------------------
resource "random_pet" "counted" {
  count  = var.pet_count
  length = 2
}

resource "local_file" "counted" {
  count    = var.pet_count
  filename = "${path.module}/generated/count-${count.index}.txt"
  content  = "Pet number ${count.index} is ${random_pet.counted[count.index].id}"
}

# --- count as an ON/OFF switch ------------------------------------------------
# count = 1 -> the resource exists, count = 0 -> it does not exist.
# Because it uses count, it is a LIST, so refer to it as local_file.optional[0].
resource "local_file" "optional" {
  count    = var.create_extra ? 1 : 0
  filename = "${path.module}/generated/optional.txt"
  content  = "I only exist when create_extra = true"
}


# =============================================================================
# 3. for_each : one copy per ITEM of a SET or MAP
# =============================================================================
# each.key   : the item (set) or the key (map)
# each.value : the item (set: same as key) or the value (map)
# Instances are addressed by KEY:  random_pet.per_owner["alice"]
#
# Removing one item removes ONLY that instance (safer than count for named items).
# -----------------------------------------------------------------------------

# --- for_each over a SET ------------------------------------------------------
resource "random_pet" "per_owner" {
  for_each = var.owners # set(string): each.key == each.value
  prefix   = each.key
  length   = 2
}

# --- for_each CHAINED from another for_each resource --------------------------
# Looping over a resource that itself uses for_each gives one file per pet.
#   each.key   -> "alice", "bob"
#   each.value -> the whole random_pet object (so each.value.id works)
resource "local_file" "per_owner" {
  for_each = random_pet.per_owner
  filename = "${path.module}/generated/owner-${each.key}.txt"
  content  = "${each.key} owns ${each.value.id}"
}

# --- for_each over a MAP ------------------------------------------------------
# each.key = owner, each.value = animal type
resource "local_file" "per_type" {
  for_each = var.pet_types
  filename = "${path.module}/generated/type-${each.key}.txt"
  content  = "${each.key} has a ${each.value}"
}

# count vs for_each
#   +-----------------+---------------------+------------------------+
#   |                 | count               | for_each               |
#   +-----------------+---------------------+------------------------+
#   | Input           | a number            | a set or a map         |
#   | Address         | resource[0]         | resource["key"]        |
#   | Loop value      | count.index         | each.key / each.value  |
#   | Remove middle   | shifts the rest     | removes only that one  |
#   | Best for        | N identical copies  | distinct named items   |
#   +-----------------+---------------------+------------------------+


# =============================================================================
# 4. provider : choose WHICH provider configuration to use
# =============================================================================
# A provider can be configured more than once using an ALIAS. A resource picks
# one with:   provider = <PROVIDER>.<ALIAS>
#
# In the cloud this is how you deploy to MULTIPLE REGIONS or ACCOUNTS:
#
#   provider "aws" { region = "us-east-1" }                  # default
#   provider "aws" { alias = "london" region = "eu-west-2" } # alias
#   resource "aws_s3_bucket" "b" { provider = aws.london ... }
#
# The random provider needs no settings, so here the alias is empty, but the
# syntax is exactly the same.
# -----------------------------------------------------------------------------
provider "random" {
  alias = "secondary"
}

resource "random_pet" "uses_alias" {
  provider = random.secondary # <PROVIDER>.<ALIAS>
  length   = 2
}


# =============================================================================
# 5. lifecycle : control create / update / destroy behavior
# =============================================================================

# A pet whose change should force the file below to be recreated.
resource "random_pet" "trigger" {
  length = 2

  lifecycle {
    # On replacement, build the NEW one first, then destroy the OLD one.
    # Safe here because random_pet has no name that can collide.
    # (Do NOT use this on a file with a fixed filename: the old resource's
    # destroy would delete the file the new one just wrote.)
    create_before_destroy = true
  }
}

resource "local_file" "lifecycle_demo" {
  filename = "${path.module}/generated/lifecycle.txt"
  content  = "Original text"

  lifecycle {
    # Ignore changes to these arguments (edited in code OR outside Terraform).
    # Use  ignore_changes = all  to ignore every argument.
    ignore_changes = [content]

    # Recreate this file whenever random_pet.trigger is replaced,
    # even though there is no reference between them.
    replace_triggered_by = [random_pet.trigger]

    # Check BEFORE creating or changing: stops the run with your message.
    precondition {
      condition     = var.pet_count >= 1
      error_message = "pet_count must be at least 1."
    }

    # Check AFTER it exists; "self" refers to this resource.
    postcondition {
      condition     = length(self.filename) > 0
      error_message = "filename must not be empty."
    }

    # SAFETY LOCK: any plan that would DESTROY this fails, including
    # `terraform destroy`. Uncomment to try it. To delete on purpose, set it
    # to false (or remove it), apply, then destroy.
    # prevent_destroy = true
  }
}


# =============================================================================
# OUTPUTS : see what each meta-argument produced
# =============================================================================

# count -> LIST. [*] (splat) means "all items"
output "count_pets" {
  description = "All pet names created with count"
  value       = random_pet.counted[*].id
}

# optional (count as a switch) -> LIST, so use [*] to be safe when it is empty
output "optional_file" {
  description = "Path of the optional file (empty list if it was not created)"
  value       = local_file.optional[*].filename
}

# for_each -> MAP. A for expression builds key => value
output "owner_pets" {
  description = "owner => pet name, created with for_each"
  value       = { for owner, pet in random_pet.per_owner : owner => pet.id }
}

output "type_files" {
  description = "owner => file path, created with for_each over a map"
  value       = { for owner, file in local_file.per_type : owner => file.filename }
}

output "alias_pet" {
  description = "Pet created using the aliased provider"
  value       = random_pet.uses_alias.id
}

output "depends_on_pet" {
  description = "Pet created after config.txt because of depends_on"
  value       = random_pet.after_config.id
}


# =============================================================================
# TRY THESE EXPERIMENTS
# =============================================================================
# 1. count        : set pet_count = 5, then back to 2. Watch which items are
#                   created and destroyed.
#                     terraform apply -var="pet_count=5"
# 2. switch       : terraform apply -var="create_extra=false"
#                   optional.txt is destroyed, the output becomes [].
# 3. for_each     : add "dave" to owners, then remove "alice". Only that one
#                   instance changes.
#                     terraform apply -var='owners=["bob","dave"]'
# 4. ignore       : edit generated/lifecycle.txt by hand, then run
#                   terraform plan. No change is planned (ignore_changes).
# 5. triggered    : terraform apply -replace="random_pet.trigger"
#                   lifecycle.txt is recreated (replace_triggered_by).
# 6. conditions   : terraform apply -var="pet_count=0"
#                   fails with the precondition error message.
# 7. graph        : terraform graph  (see which resources run in parallel)
# =============================================================================
