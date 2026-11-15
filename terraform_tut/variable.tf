variable "file-content" {
    type  = map  
    default =  {
        "statement1" = "We love Pets"
        "statement2" = "We love animals"
    }
}

variable "prefix" {
    default = ["Mr", "Mrs", "Sir"]
    type = list(string)
}

# list
variable "prefix2" {
    default = [1, 2, 3]
    type = list(number)
}

# Set
variable "age" {
    default = [10, 12, 15]
    type = set(number)
}

# object
variable "bella" {
    type = object({
      name = string
      color = string
      age = number 
      food = list(string)
      favorite_pet = bool 
    })

    default = {
      name = "bella"
      color = "brown"
      age = 7
      food = [ "fish", "chick" ]
      favorite_pet = true
    }
}

# Tuples: Element of different variable types
variable "kitty" {
    type = tuple([ string, number, bool ])
    default = [ "cat", 7, false ]
}