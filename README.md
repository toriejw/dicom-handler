# dicom-handler

## Table of Contents

- [Local Setup](#local-setup)
- [API Documentation](#api-documentation)
  - [POST /images](#post-images)
- [Assumptions Made](#assumptions-made)
- [Production-code Improvements](#production-code-improvements)
- [Code Walkthrough](#code-walkthrough)

## Local Setup

You will need to have a ruby version manager installed locally. If you don't already, I'd recommend `rbenv`, which can be installed using `brew install rbenv`.

1. Install Ruby version 3.3.0. If using `rbenv`, you can do so using: `rbenv install 3.3.0`
2. Clone repo: `git@github.com:toriejw/dicom-handler.git`
3. Install imagemagick: `brew install imagemagick` 
4. Install repo packages: `bundle install`
5. Ensure install was successful by running `rails s`. You should see a server start. You can further confirm setup was successful by following instructions in the testing section below.

## Testing

To run tests locally, you can use: `bundle exec rspec`

To test against the local server, you can use the following curl request. Make sure you update the image path to match your local directory.
```
curl -X POST "http://localhost:3000/api/v1/images?tags[]=0002,0013&tags[]=0018,0050&tags[]=0040,0244" \
  -F "image=@/code/dicom-handler/spec/fixtures/images/mri/SE000008/IM000001.dcm" \
  -H "Accept: application/json"
```
You should receive a successful response, and see your uploaded DICOM image and corresponding PNG in `/public/uploads`.

## API Documentation

### POST /images

This API stores and converts a DICOM image into a PNG. It can also be used to return DICOM header attribute values.

The endpoint accepts the following parameters:


| Param | Type | Description | Required? |
|-------|------|-------|----------|
| `image` | DICOM image | Image to be uploaded| Yes |
| `tags` | array | A list of DICOM tags (can be passed in as query or request parameters) | No |

The endpoint returns:

| Param | Type | Description |
|-------|------|-------|
| `attributes` | Key/value pair | Requested DICOM tags and their associated values|

Example request:
```
curl -X POST "http://localhost:3000/api/v1/images?tags[]=0002,0013&tags[]=0018,0050&tags[]=0040,0244" \
  -F "image=@/Users/torie/code/tutorials/dicom-handler/dicom-handler/spec/fixtures/images/mri/SE000008/IM000001.dcm" \
  -H "Accept: application/json"
```

Example response:
```
{
    "message":"Success",
    "attributes": {
        "0002,0013":"IMS4-6-1-P95",
        "0018,0050":"3.0",
        "0040,0244":"20131217"
    }
}
```

## Assumptions Made

1. Authentication/authorization is not (yet) required. Because the API only accepts an image the user already has access to, there is no risk of exposing information that the user doesn't already have apart from accessing other images stored in local storage. Using local storage to store the files is a security risk, as file paths can be scanned, but we're using local storage here for the sake of time. In a production environment, we should be considering how to safely handle a stored image to prevent unauthorized access.
2. We want to store both the original DICOM file and the PNG file.
3. Our use case requires a single API. Using a purely RESTful API pattern, I would create a POST endpoint for storing the image, and a GET endpoint for querying tags on the image. I've combined those into one API based on the requirements specifying creating a single API.
4. The PNG file path should not be returned, since in the current implementation there is no way to access it. Having a file path with no ability to access it does not provide any value to the user. Since we're using local storage, it also exposes the file paths we're using, which could provide a potential attacker with more information than we need to.
5. This API would eventually be a part of a web app. The repo uses a full Rails app, rather than an API-only version of Rails.

## Production-code Improvements

For production code, here are some of the things I would do differently:

1. Ensure the endpoint is only accessible using HTTPS. In Rails, this would be configured on deployment and requires specific configuration to use locally (eg. set up with `ngrok`).
1. Remove any unused Rails generated code/files to prevent bloat.
2. Use S3 (or something similar) for file storage, and return a temporary, secure URL to the user to view the image.
3. Learn more about DICOM! It seems like a file type with a lot of complexity, and before doing this "for real" I'd want to better understand how it works, especially any potential gotchas and best practices.
4. Add unit tests for `DicomImage`. Currently the feature tests cover that class, but for a robust test suite, I'd also want unit tests.

## Code Walkthrough

Just in case you're not familiar with Rails, here's a quick rundown of what code files are important.

This repo contains a single API, `POST /images`, with the route defined in [routes.rb](./config/routes.rb).

The route definition points to the [ImagesController](./app/controllers/api/v1/images_controller.rb), where request processing is handled for the endpoint.

The controller makes use of the [DicomImage](./app/models/dicom_image.rb) model to handle the bulk of the logic.

Finally, the test file for the endpoint lives in [images_spec.rb](./spec/requests/api/v1/images_spec.rb).
