# static-gravatar-server
This project implements a [Gravatar](https://gravatar.com) compatible service for accessing avatars with simple static hosting using nginx and offline image generation. It targets a closed environment, e.g., an enterprise network with services that allow using Gravatar with custom base URLs such as Redmine and Gerrit. It intentionally provides neither a fallback to Gravatar nor to [Libravatar](https://libravatar.org/) for zero information leakage. This project does not contain a web frontend and the upload of avatars is out-of-scope.

This project comprises an nginx configuration snippet to serve images following a specific directory structure and a bash script that generates this structure based on a set of input images for email addresses. I assume it should be possible to convert the nginx configuration to Apache or other web servers but have not looked into it (PRs are welcome). The bash script is not required on the web server - only the directory with the generated images is needed.

Additionally, the docker image `isotes/static-gravatar-server-prepare` built from this accompanying [Dockerfile](Dockerfile) that can be used for the image generation if the necessary dependencies (primarily ImageMagick) are not available locally.


## Nginx Configuration
The nginx configuration file [gravatar.conf](gravatar.conf) assumes the service runs under `/avatar` and the images are available under `$(server-root)/avatar`. Either `include` the provided snippet directly or copy and modify the configuration as needed.


## Image Generation
The image generation script expects a directory structure like this:
```
.
├── default.svg
├── example.com
│   ├── users.txt
│   ├── user1.png
│   └── user2.png
└── foo.example.com
    └── another.user.svg
```

The first level consists of one directory per email domain used. Each directory contains an image file for each email address in that domain, e.g., the above example provides avatars for `user1@example.com`, `user2@example.com` and `another.user@foo.example.com`.

All image types supported by the used `convertImg` command (see below) are allowed. The images must be quadratic.

In addition to the image file, each domain directory may contain a file `users.txt` listing all known users one line at a time. The script checks this file and automatically generates an image for all users listed that do not have a corresponding image file.

Finally, a default image `default.*` is required for providing the fallback images for an unknown email address. By default, the expected type is `svg` but that can be overridden. A suitable image can be found on [Wikimedia](https://en.wikipedia.org/wiki/File:Missing_avatar.svg).

Run the script [`prepare`](prepare) to resize and convert the images as preparation for static hosting. Alternatively, use the docker image containing the script as follows:
```bash
docker run -v "$PWD:/x" -u $UID isotes/static-gravatar-server-prepare
```


### Customizing
Relevant variables and functions in the `prepare` script are only set to default values and default implementations if not already defined. The `prepare` script accepts paths to bash snippets as optional command line arguments. These files are sourced at the beginning of the script which allows customization by defining these variables and functions beforehand. For example, by creating a file `my-dirs` containing
```bash
inputDir=here
outputDir=there
```
and calling `prepare my-dirs`, it is possible to specify the input and output directory.

The script itself contains comments for the available variables and functions. For example, the auto-generation of avatars for email addresses without images is implemented as the function `generate` that creates an SVG image based on the initials of the email. By defining an alternative `generate` function, it is possible to make use of other solutions such as [Identicons](https://en.wikipedia.org/wiki/Identicon) (for example services see the 'Default URL for missing images' section of the [Libravatar API description](https://wiki.libravatar.org/api/)).


### Incremental Build
The `prepare` script works incrementally: for each email, it compares the input image with a backup stored in the previous run. If they are equal, only missing images will be generated, i.e., if the configuration has changed and more sizes or more image types are needed. This implies that if the `imgConvert` function has changed so that it will produce other results, the existing images must be manually deleted beforehand.

The `prepare` script does not delete images: neither for unused sizes nor types nor email addresses.


## SVG Images
I had decidedly mixed results when experimenting with SVG images for auto-generating missing images. While my original attempt looked good in Chrome, converting with ImageMagick, RSVG, or Inkscape produced results lacking to various degrees. The current approach for the auto-generation has been successfully tested with ImageMagick. However, if SVG is used for input files, your mileage may vary. Installing Inkscape alongside ImageMagick, which will then automatically use Inkscape for SVG conversion, might improve results.


## Requirements
I am not aware of any special requirements of the nginx configuration snippet.

Out of the box, the bash script supports a local [ImageMagick](https://imagemagick.org/) installation and a docker image with ImageMagick. See the comments in the script for providing a custom `convertImg` function. Additionally, the script requires a few common command line tools such as `md5sum`, `diff`, `grep`, etc.


## Implemented API
This project implements the [Gravatar Image Request API](https://en.gravatar.com/site/implement/images/) with the following limitations:
- the 'Force Default' parameter is ignored
- rating-specific images are not supported and the corresponding parameter is ignored
- default image types (identicon, ...) except for `404` are ignored and return the same static (email-independent) image
- default image URLs and their content are not checked or sanitized in any way


## Image Hosting Directory Structure
The first level of the directory structure expected by the nginx configuration and created by the image generation script consists of one directory for the MD5 hashes of each email. Each of these directories contains one image per each combination of SIZExTYPE (`16.png`, `64.jpg`, etc.).  Additionally, for each image type it contains `org.TYPE` which is served if the requested size is not present. Finally, each directory contains the original image as `original.ORIGINAL-TYPE` that is used by the `prepare` script to check if existing images must be overwritten. A directory with the same structure and the name `default` is created for the fallback image.


## Acknowledgements and Alternatives
This project originally started from [libravatar-nginx](https://avatars.shivering-isles.com/) but has become a complete rewrite due to a different focus and other design choices. That projects offers a turn-key solution in form of a docker image and fallback to Libravatar/Gravatar.

[Libravatar](https://libravatar.org/) - a federated Open Source approach that also implements the Gravatar API - maintains a [list of server implementations](https://wiki.libravatar.org/running_your_own/).


## License
[Apache 2.0](LICENSE)
