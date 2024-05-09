terraform {
  cloud {
    organization = "SayanOrg"

    workspaces {
      name = "atlantis-test"
    }
  }
}