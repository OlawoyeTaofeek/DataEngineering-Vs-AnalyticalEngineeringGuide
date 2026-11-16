output "pet_name" {
  value       = random_pet.my_pet.id
  description = "The generated pet name"
}

output "file_path" {
  value = local_file.my-pet.filename
}