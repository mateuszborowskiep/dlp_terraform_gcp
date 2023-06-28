# Define the provider and required variables
provider "google" {
  project = "rosy-crawler-389806"
  region  = "europe-west1"
}

# Enable the DLP API
resource "google_project_service" "dlp" {
  service = "dlp.googleapis.com"
  project = "147439111951"
}

# Create a Cloud Storage bucket
resource "google_storage_bucket" "my_bucket" {
  name     = var.bucket_name
  location = "europe-west1"
}

# Configure the DLP inspect template
resource "google_data_loss_prevention_inspect_template" "my_inspect_template" {
  parent = "projects/rosy-crawler-389806"
  display_name     = "My Inspect Template"
  description      = "Template for data inspection"
    inspect_config {
        info_types {
            name = "EMAIL_ADDRESS"
        }
        info_types {
            name = "PERSON_NAME"
        }
        info_types {
            name = "LAST_NAME"
        }
        info_types {
            name = "DOMAIN_NAME"
        }
        info_types {
            name = "PHONE_NUMBER"
        }
        info_types {
            name = "FIRST_NAME"
        }

        min_likelihood = "UNLIKELY"
        rule_set {
            info_types {
                name = "EMAIL_ADDRESS"
            }
            rules {
                exclusion_rule {
                    regex {
                        pattern = ".+@example.com"
                    }
                    matching_type = "MATCHING_TYPE_FULL_MATCH"
                }
            }
        }
        rule_set {
            info_types {
                name = "EMAIL_ADDRESS"
            }
            info_types {
                name = "DOMAIN_NAME"
            }
            info_types {
                name = "PHONE_NUMBER"
            }
            info_types {
                name = "PERSON_NAME"
            }
            info_types {
                name = "FIRST_NAME"
            }
            rules {
                exclusion_rule {
                    dictionary {
                        word_list {
                            words = ["TEST"]
                        }
                    }
                    matching_type = "MATCHING_TYPE_PARTIAL_MATCH"
                }
            }
        }

        rule_set {
            info_types {
                name = "PERSON_NAME"
            }
            rules {
                hotword_rule {
                    hotword_regex {
                        pattern = "patient"
                    }
                    proximity {
                        window_before = 50
                    }
                    likelihood_adjustment {
                        fixed_likelihood = "VERY_LIKELY"
                    }
                }
            }
        }

        limits {
            max_findings_per_item    = 10
            max_findings_per_request = 50
            max_findings_per_info_type {
                max_findings = "75"
                info_type {
                    name = "PERSON_NAME"
                }
            }
            max_findings_per_info_type {
                max_findings = "80"
                info_type {
                    name = "LAST_NAME"
                }
            }
        }
    }
}

# Configure the DLP job trigger
resource "google_data_loss_prevention_job_trigger" "my_job_trigger" {
  parent = "projects/rosy-crawler-389806"
  display_name     = "My Job Trigger"
  description      = "Trigger for DLP job"

triggers {
        schedule {
            recurrence_period_duration = "86400s"
        }
    }

    inspect_job {
        inspect_template_name = "fake"
        actions {
            save_findings {
                output_config {
                    table {
                        project_id = "project"
                        dataset_id = "dataset"
                    }
                }
            }
        }
        storage_config {
            cloud_storage_options {
                file_set {
                    url = "gs://${google_storage_bucket.my_bucket.name}/**"
                }
            }
        }
    }
}

# Configure Cloud Storage bucket IAM binding
resource "google_storage_bucket_iam_binding" "my_bucket_iam_binding" {
  bucket = google_storage_bucket.my_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "user:admin@cloudsecurity.team"
  ]
}