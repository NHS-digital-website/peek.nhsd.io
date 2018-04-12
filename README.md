# peek.nhsd.io dashboard

To build the site, run `make clean build`. Site will be ready in `out/` folder.

Deploy to S3 bucket

```
$(make aws-sudo PROFILE=... TOKEN=...)
make deploy
```
