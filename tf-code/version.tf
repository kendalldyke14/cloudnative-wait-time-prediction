#### Configure backend ####
terraform {
backend "gcs" {}
required_providers {
google = {
source = "hashicorp/google"
version = "~>3.64.0"
}
}
}