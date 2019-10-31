# vOSE Introduction

VMware VCPP program enables our service providers to sell computing resources to their customers. Object Storage Service (a.k.a blob, OSS) is a key service in today's cloud and SaaS offering for app level customers to build up various applications. There are typically two ways to offer an OSS for a service provider:

- By building an OSS solution upon their in house storage
- By purchasing public cloud storage from a 3rd party vendor (e.g. Amazon S3, Microsoft Azure, Google Cloud Storage, etc.)

(1) brings direct revenues to service providers, but it is also expensive to build up & maintain such a solution by themselves. (2) is rapidly ready-for-use but the majority of the revenues are going to cloud storage vendors. In this project, we build an OSS for service providers, which enables them to sell their in house & heterogeneous storage as object storage services. The main functionality of this solution that differs from any public cloud storage is, VMware is going to provide the OSS extension to service providers, and service providers are going to enable OSS instances and sell multi-tenancy storage to their customers.

Our objective is to build a multi-tenant Object Storage Service for cloud providers, which is aimed to provide the following benefits

- Enable a provider to offer a service with its in-house storage capacity
- Enrich VMware vCloud Director ecosystem
- Bring revenues to both VMware and cloud providers
- Support different object storage vendors preferred by cloud providers
