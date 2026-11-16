resource "local_file" "pet2" {
  filename = var.filename
  content  = "My favorite pet is ${random_pet.my_pet.id}"

  lifecycle {
    create_before_destroy = true    # on replacement, create the new one first, then delete the old
    ignore_changes        = [content] # ignore changes to content (made in code or outside Terraform)
  }
}

resource "random_pet" "my_pet" {
  prefix    = var.prefix[0]
  separator = var.separator
  length    = var.length

  lifecycle {
    create_before_destroy = true

    # Rejects with an error any plan that would DESTROY this resource:
    #   - a change that forces replacement (-/+)
    #   - `terraform destroy`
    # Useful for things you can't easily recreate (e.g. a database).
    # It does NOT protect against: deleting this resource block from the code,
    # setting prevent_destroy = false, or `terraform state rm`.
    # To delete on purpose: set it to false (or remove it), apply, then destroy.
    prevent_destroy = true

    # Ignore changes to ALL arguments (prefix, separator, length).
    ignore_changes = all

    # Runs BEFORE the resource is created or changed
    precondition {
      condition     = var.length >= 2
      error_message = "length must be at least 2."
    }

    # Runs AFTER the resource exists; `self` refers to this resource
    postcondition {
      condition     = length(self.id) > 3
      error_message = "Pet name is too short."
    }
  }
}