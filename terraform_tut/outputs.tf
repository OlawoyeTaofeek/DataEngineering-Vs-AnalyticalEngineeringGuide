output "pet_name" {
  value       = random_pet.my_pet.id
  description = "The generated pet name"
}

output "file_path" {
  value = local_file.my-pet.filename
}

output "module_path" {
  value = path.module
}

output "root_path" {
  value = path.root
}

output "current_dir" {
  value = path.cwd
}

output "full_module_path" {
  value = abspath(path.module)
}

output "file_full_path" {
  value = abspath("${path.module}/pets.txt")
}