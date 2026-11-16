resource "local_file" "pet2" {
  filename = var.filename
  content  = "My favorite pet is ${random_pet.my_pet.id}"
}

resource "random_pet" "my_pet" {
  prefix    = var.prefix[0]
  separator = var.separator
  length    = var.length
}