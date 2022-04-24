# Image

The `conformance.yml` task uses the `ismteam/osb-checker-kotlin` Docker image.
The `Dockerfile.osb-checker-kotlin` file is what is used to build that image.

To rebuild the image if required (e.g. after changing the Dockerfile):

```
docker build -f Dockerfile.osb-checker-kotlin -t ismteam/osb-checker-kotlin . &&
docker push ismteam/osb-checker-kotlin
```
