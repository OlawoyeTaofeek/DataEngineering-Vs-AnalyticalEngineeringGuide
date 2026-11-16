# --- Variables ---------------------------------------------------------
variable "filename2" {
  type        = string
  description = "File that Terraform CREATES"
  default     = "C:/Users/user/Desktop/snowflake_lesson/pets.txt"
}

variable "source_filename" {
  type        = string
  description = "Existing file the data source READS (must exist before plan)"
  default     = "C:/Users/user/Desktop/snowflake_lesson/dogs.txt"
}

# --- Data source -------------------------------------------------------
# A data source is READ-ONLY. It looks up something that already exists
# and exposes it as attributes; it never creates, changes or deletes it.
#
# Here it reads dogs.txt, a file created OUTSIDE Terraform.
#   - It is read during `terraform plan`, so the file must exist beforehand,
#     otherwise the plan fails.
#   - Do NOT point it at a file that a resource in this config creates
#     (that causes a chicken-and-egg problem on the first run).
#   - It is NOT destroyed by `terraform destroy`; dogs.txt stays untouched.
#   - It is re-read on every plan, so edits to dogs.txt are picked up.
# Reference its values with the `data.` prefix:
#   data.local_file.copy.content   -> the text inside dogs.txt
data "local_file" "copy" {
  filename = var.source_filename
}

# --- Resources ---------------------------------------------------------
resource "random_pet" "my_pet2" {
  prefix    = var.prefix[0]
  separator = var.separator
  length    = var.length

  lifecycle {
    create_before_destroy = true
  }
}

# Creates pets.txt using a value from the random_pet resource
resource "local_file" "pet3" {
  filename = var.filename2
  content  = "My favorite pet is ${random_pet.my_pet.id}"

  lifecycle {
    create_before_destroy = true      # on replacement, create the new one first, then delete the old
    ignore_changes        = [content] # ignore changes to content (made in code or outside Terraform)
  }
}

# Creates a DIFFERENT file (dogs_copy.txt) using the text read by the data source
resource "local_file" "dog_pet" {
  filename = "${path.module}/dogs_copy.txt"
  content  = data.local_file.copy.content   # value read from the existing dogs.txt

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [content]
  }
}

resource "local_file" "test_pet" {
  filename = "${path.module}/pets2.txt"
  content  = "hello"
}

output "created_file" {
  value = abspath(local_file.pet.filename)
}