# Bookshelf App

## Project Characteristics

1. A bookshelf app that uses object storage technology.
1. Support different object storage vendors like vOSE, AWS preferred by cloud providers
1. Compatible with Amazon S3 API
1. Access control list (ACL) helps a user share books with others
1. Easy to switch between public cloud and private cloud
1. Use Flutter to support multiple platforms, such as iOS, Android, Web

## vOSE Standalone Access

Access `http://yhzzzz.natapp1.cc` and send request `http://yhzzzz.natapp1.cc/api/v1/admin/current-user` with request header `x-vcloud-authorization: <username>@<tenant>:jiaotong` to vOSE server.

## Reference

- Documentation: <https://docs.vmware.com/en/VMware-vCloud-Director-Object-Storage-Extension/>
- Swagger API doc: <https://code.vmware.com/apis/665/vose>
- Swagger: <https://vdc-download.vmware.com/vmwb-repository/dcr-public/11a19b18-f47e-404d-8378-fef6a187c9a7/b5d43629-8523-4d80-8cfb-00e169d9f2b9/vose-swagger-1.0-final.json>
