resource "local_file" "my-pet" {
    filename = "C:/Users/user/Desktop/snowflake_lesson/pets.txt"
    content = var.file-content["statement2"]
}