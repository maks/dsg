# DSG: A Dart Static Site Generator 

Includes support for:
* commonmark (markdown) content 
* mustache templates
* template partials
* yaml front-matter
* json / yaml data processing
* a webserver

*think: Jekyll for Dart*

## Use as an executable

You can either install dsg with pub:
```
dart pub global activate dsg
```

or you can just download the self-contained executable for your platform from the [Github repo](https://github.com/maks/dsg/actions).

See [this article on how DSG came to be and how you can use it to deploy your website](https://medium.com/flutter-community/same-site-new-tools-7a3fd5d5f517).

## Example

   - Install DSG (see above)
   - Download the sample [simple.tgz](https://github.com/jsiedentop/dsg/blob/main/downloads/simple.tgz)
   - cd into the local `simple` dictionary
   - run `dsg -x`

Play with the sample files...
     
#### Support for https-connection! 
This is absolutely mandatory if your REST-Server
uses [HTTP Strict Transport Security (HSTS)](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security)

At `samples/simple/.sitegen/site.yaml`` you can see the necessary configuration for HTTPS-Support   
Generate a self-signed certificate, name it dart.cert and dart.key, place it under <project root>/etc 
and run `dsg -x --usesec` and - voila. That's it!


### What it does
DSG is a static site generator in [Dart](https://www.dartlang.org/), with a webserver included.
It supports extra assets-folder and template partials.  
You can write your pages in HTML or [CommonMark aka "Markdown"](https://commonmark.org/) is supported.
  
A webserver for a quick previews is included. On Mac you also get automatic page refresh. On other 
platforms you could try [LivePage](https://chrome.google.com/webstore/detail/livepage/pilnojpmdoofaelbinaeodfpjheijkbh) 
chrome extension for maximum productivity.  

main
You can see a [typical site structure](https://github.com/maks/dsg/tree/main/build/samples/simple) in this repository. For a working example, please download the [simple.tgz](https://github.com/jsiedentop/dsg/blob/main/downloads/simple.tgz), that contains all the necessary configuration files. 

See [manichord.com](https://manichord.com) for a site built entirely with DSG.   

```
├── .sitegen
│   ├── html
│   │   ├── _content
│   │   │   ├── about
│   │   │   │   └── index.html
│   │   │   ├── assets
│   │   │   │   ├── images
│   │   │   │   │   ├── android-desktop.png
│   │   │   │   │   ├── favicon.png
│   │   │   │   │   └── ios-desktop.png
│   │   │   │   └── styles
│   │   │   │       └── styles.scss
│   │   │   ├── features.html
│   │   │   ├── index.html
│   │   │   ├── main.dart
│   │   │   ├── markdown.md
│   │   │   ├── special
│   │   │   │   ├── template.html
│   │   │   │   └── xtreme.html
│   │   │   └── technology.html
│   │   ├── _data
│   │   │   ├── families.json
│   │   │   ├── items.json
│   │   │   ├── menu.json
│   │   │   ├── sitemap.json
│   │   │   └── xmen.yaml
│   │   ├── _partials
│   │   │   ├── cards
│   │   │   │   └── wide.html
│   │   │   └── header.html
│   │   │   └── list.html
│   │   └── _templates
│   │       ├── default.html
│   │       └── info_page.html
│   └── site.yaml
├── pubspec.yaml
└── etc
    ├── dart.crt
    └── dart.key
└── web
    ├── about
    │   └── index.html
    ├── assets
    │   ├── images
    │   │   ├── android-desktop.png
    │   │   ├── favicon.png
    │   │   └── ios-desktop.png
    │   └── styles
    │       ├── styles.css
    │       └── styles.scss
    ├── features.html
    ├── index.html
    ├── main.dart
    ├── markdown.html
    ├── special
    │   ├── template.html
    │   └── xtreme.html
    └── technology.html
```

**.sitegen**: This is where your (optional) site.yaml lives  
This folder is also used to store autgenerated scripts - in the case above you can see
the script to refresh Chromium on Mac.

**.sitegen/html/_content**: This is where **DSG** will look for your files to generate the site from.
The following file-formats are supported:

- .md
- .markdown
- .dart
- .js
- .json
- .html
- .scss
- .css

**.sitegen/html/_data**: [optional] This is the place where you can store your data-files.  
The following file-formats are supported:
- .yaml
- .json

**DSG** injects your data into a global _data variable.
Here is a sample how to use such data:
  
```html
<ul>
    {{#_data.xmen}}
    <li>{{.}}</li>
    {{/_data.xmen}}
</ul>
```

**.sitegen/html/_listings**: [optional] This is the place where you can store your listings configuration files.  
Listing files are in yaml format with the following parameters supported: `path`, `filter`, `sort_by`

The `path` is a path relative to `.sitegen/html/_content`.
The `filter` specifies which files to list within the given path.
The `sort_by` specifies a property **AND** the `ASC` or `DESC`.

eg. to sort in chronological descending order based on a front-matter property called `pub_date`

```yaml
path: blog
filter: "*.md"
sort_by: pub_date DESC
```

**DSG** injects your listings into a global `_lists` variable. For each file all of the files YAML front-matter properties are available along with the files:

* `filename`:  the files name without extension.
* `last_modified`: the files last modified date time stamp.

Here is a sample how to use a listing:
  
```html
<ul>
    {{#_lists.blog}}
    <li>{{ title }}</li>
    {{/_data.blog}}
</ul>
```

**.sitegen/html/_assets**: [optional] Additional assets that you don't want to have in _content. The following file types are supported:
* .scss 
* .jpg
* .png
* .gif
* .woff
* .ttf
* .pdf

**.sitegen/html/_templates**: The directory containing your HTML+Mustache templates.

**web**: Following Dart conventions - this is your default **output** directory.

### Top-level files

Sometimes you will need to place specific files in the top level of your website, for example `favicon.ico` or `robots.txt`. These files can simply be placed in the `.sitegen/html/_content` folder and will then be copied across to the `web` output folder. See the [simple.tgz](https://github.com/jsiedentop/dsg/blob/main/downloads/simple.tgz).


## site.yaml
**Optional** [YAML](https://rhnh.net/2011/01/31/yaml-tutorial) file that stores your global values and config options.
Values set here can be accessed from all templates and markdown files.

```
site_options:
  author: Maksim Lin
```

Can be used in your template (default.html) as
```
<span>{{_site.author}}</span>
```

You can also use site.yaml to overwrite your **dsg** default configuration.  
Supported vars:

- content_dir: .sitegen/html/_content 
- template_dir: .sitegen/html/_templates
- data_dir: .sitegen/html/_data
- partials_dir: .sitegen/html/_partials
- assets_dir: .sitegen/html/_assets
- output_dir: web
- workspace: .
- date_format: dd.MM.yyyy
- yaml_delimeter: ---
- use_markdown: true
- default_template: default.html
- browser: Chromium
- watchfolder1, watchfolder2 and watchfolder3

## Markdown
**DSG** lets you use [CommonMark aka "Markdown"](https://commonmark.org/) to write your site content.

At the beginning of each markdown file, you
have the option to use a [YAML](https://rhnh.net/2011/01/31/yaml-tutorial) "front-matter" block to define custom values that you can inject into your templates. Example:

    ---
    title: A Blog Post
    published: 01/01/2014
    category: example
    tags:
        - StillShot
        - Rants
        - Etc.
    ---
    {{title}}
    Normal Markdown content here...

As you can see, a line of dashes (`-`) is used to delimit your YAML block (marking start and end lines). You can access/inject your values into
your pages using [mustache template syntax](https://mustache.github.io/mustache.5.html). You can do this either inside your dedicated HTML/mustache templates:

    <ul>
      {{#tags}}
        <li>{{.}}</li>
      {{/tags}}
    </ul>

Or, you can embed your values within the markdown file itself:

    {{#tags}}
      - __{{.}}__
    {{/tags}}

so you can take advantage of templating and markdown at the same time.

Simply place all your files in your `content_dir` and **DSG** will generate your site accordingly.      
If your markdown file has a .md extension it will be renamed to .html.
    
## Templates
As mentioned above, you can access any variables set within your markdown files from your templates using mustache. Options
set from your `site.yaml / site_options` can be accessed through the `_site` variable, like so:

    <h1>{{ _site.author}}</h1>

where `author` is a property defined in your `site.yaml / site_options`. 
You can access these values from your markdown or from your html files.

Every page and template has access to the following values:

- `title`: title, usually set inside each markdown file, but is set to the name of markdown file if left blank
- `_site`: site.yaml values
- `_date`: the post/markdown file's _last modified_ date
- `_content`: converted markdown content (only accessible from templates)
- `_page.relative_to_root`: will be replaced with some '../' depending on the nesting level of your page (check about/index.html)
    
The default template is 'default.html' but you can overwrite this behavior if you add a 'template' var to the yaml-block of your content file.

    template: info_page
    
    
## Partials 
**Optional**  
Files / Directories in your _partials-Folder will be translated into partials-names.  
For example: _partials/category/house.md translates into {{>category.house}}  
A partial can be either a .md or a .html file

You can also use partials in the files yaml block:
```yaml
---
template: default.html    
dart: ->usage.badge.dart  
---  
```

## Template Functions

Mustache provides for the use of "lambdas" which are essentially names functions that can be accessed in templates using the section syntax.
The currently available functions in DSG are listed below.

### formatDate

Allows formating either a hard coded string or another template variable written in the format `yyyy-MM-dd` the function will ouput the it using the format specified in `date_format` in `site.yaml`.

eg. given in site.yaml a `date_format: dd MMM yyyy` and then a variable defined in your front-matter like `article_date: 2020-01-26`
and then a template with:
```mustache

Article published on: {{# formatDate }} {{ date }} {{/ formatDate }} 

```
will output: `Article published on: 26 Jan 2020`

# Install
Install
```shell
    dart pub global activate dsg
```

Update
```shell
    # activate dsg again
    dart pub global activate dsg
```

Uninstall
```shell
    dart pub global deactivate dsg   
```    
    
## Usage    
```shell
Usage: dsg [options]
    -s, --settings         Prints settings
    -h, --help             Shows this message
    -g, --generate         Generate site
    -w, --watch            Observes SRC-dir
    -x, --watchandserve    Shortcut to watch and serve
    -i, --init             Initializes your site
                           (not combinable with other options)

        --serve            Serves your site

        --ip               Sets the IP-Address to listen on
                           (defaults to "127.0.0.1")

        --port             Sets the port to listen on
                           (defaults to "8000")

        --docroot          Document root
                           (defaults to "web")

    -v, --loglevel         Sets the appropriate loglevel
                           [info, debug, warning]

Sample:

    'Generates all basic files and folders:                'dsg -i'
    'Observes the default dirs and serves the web-folder:  'dsg -w --serve'
    'Observes the default dirs and serves the web-folder:  'dsg -x'
    'Generates the static site in your 'web-folder':       'dsg -g'
```

Go to your project root (this is where your pubspec.yaml is) and type:

    `dsg -i`
    
This creates a basic file structure for you.     

Now type

    `dsg -x`
    
This serves your files under `https://localhost:8000/`    
        
If you are using Chromium on Mac you will get a automatic page refresh for free!
 
## Hints
- Just serve a local dir on port 8000 without generating something:  
    `dsg --serve --docroot .`
    
- DSG observes automatically it's basefolders like `_content`, but if
    you want additional folders that should be observed so that dsg automatically regenerates it's
    file - set watchfolder[1-3] in you site.yaml
    
- Test your App with Chrome and use dsg as server (MAC + Linux only)  
    `dart pub build && cd build/web && dsg --serve --port 9000 --docroot . || cd -`
    
    *Explanation:*  
    Runs "dart pub build" - if this runs without errors cd to "build/web"
    In "build/web" run dsg as server on port 9000 and set docroot to . (current dir (default would be "web"))  
    || means if the prev command ends with an error (Ctrl + C to cancel dsg)   
    jump back where you came from. You should be back in your base folder (where your pubspec.yaml is)
    
 

### Features and bugs

Please file feature requests and bug reports in the [issue tracker](https://github.com/maks/dsg/issues).

### Thanks

I want to thank **Michael Mitterer** for his [SiteGen](https://github.com/MikeMitterer/dart-sitegen) 
package that I used as a starting point for **DSG**. 

### License

    Copyright 2020 Maksim Lin (admin@manichord.com), Manichord Pty Ltd

    Copyright 2019 Michael Mitterer (office@mikemitterer.at),
    IT-Consulting and Development Limited, Austrian Branch

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
    either express or implied. See the License for the specific language
    governing permissions and limitations under the License.
