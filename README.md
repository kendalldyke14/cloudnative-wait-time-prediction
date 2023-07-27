# Cloud Native Theme Park Wait Time Data Pipeline & Prediction

Walt Disney World's Approach to a data-driven guest experience is what initially interested me in the field of data. 🏰🎢 I've always been amazed by how seamlessly it can impact my Disney day for the better. Now that I have the skills and knowledge to do so, I started to dive deeper into this passion and interest. This started with the Capstone project for my Masters Degree. I'd love for you to read more about that [here.](https://medium.com/@kendalldyke/once-upon-a-wait-time-239c2228030b)

This project is intended to be an extension to my capstone. I'm taking it one step further. I'll be building out a full end-to-end cloud data project, from resource creation with Terraform, to data ingestion with GCP Cloud Scheduler, Pub/Sub, and Cloud Functions. 

🚧 This is a work in-progress, so feel free to share any feedback or ideas! 🚧 👷‍♀️

## Architecture & Infrastructure

🏗️ Terraform: Generates & maintaines all cloud resources required for this project.
💽 Cloud Scheduler, Pub/Sub & Cloud Functions:  Ingests wait time data every 15 minutes during park hours and writes to cloud storage.
🗄️ Cloud Storage: Acts as a external table to the BigQuery staging table.
☁️ BigQuery: This is the main structured data source for the project.


## Planned Next Steps

Dataflow Pipeline: This pipeline will clean the data and combine data from other sources like ride metadata, park metadata and more.
Looker Dashboard: This will be a user friendly view of current wait times, historical wait times and predictions.
Machine Learning Model: This model will predict wait times to help theme park guests plan their day efficiently.
 
 [Powered by Queue-Times.com](https://queue-times.com/en-US)