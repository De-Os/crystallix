# crystallix

A little web-server on `Crystal` which supports static files and `CGI languages` (tested with PHP)

## Installation

* Download release package (https://github.com/De-Os/crystallix/releases) and extract into empty folder
* Or build it yourself:
  1. `git clone https://github.com/De-Os/crystallix`
  2. `cd crystallix`
  3. `crystal build --release --progress src/crystallix.cr`

## Usage

Just run
```bash
./crystallix
```

## Configs

*Crystallix searches configuration files only in `cfg` folder*

Currently there are 2 configs: `config.json` and `sites.json`

### config.json (main config)
* `port` - main port (default - `80`)
* `address` - address which Crystallix will use (default - `0.0.0.0`)
* `addons` - CGI extensions path (default - `{"php": "/usr/bin/php-cgi"}`), use it like `"extension, without dot": "executable path"`

##### SSL configuration (https)
*THAT SECTION MAY NOT WORK, didn't test it*

There is `ssl` section in config to configurate SSL:

* `use?` - enable/disable SSL (default - `false`),
* `port` - SSL port (default - `443`)
* `chain` - path to chain file (default - `cfg/ssl/chain.crt`)
* `key` - path to key file (default - `cfg/ssl/private.crt`)

### sites.json

Configuration for all sites stored in `@`:
* `path` - path to the site folder (default - `pages/tests/`), required
* `index` - array with indexes to try if file directory specified in url (default - `["index.php", "index.html"]`), required
* `errors` - list with custom pages for status code (default - `{"404": "%site_path%/errors/404.html"}`, `%site_path%` tells Crystallix to use site path), optional:
```json
"errors": {
    "404": "%site_path%/errors/404.html",
    "403": "%site_path%/errors/403.html",
    "500": "%site_path%/errors/500.html"
}
```
Error files can't load anything from its directory, so include scripts, styles, etc in themselves

##### For subdomains (tested)/many domains (not tested) specify individual list:
```json
"@": {...},
"sub.domain.com": {
    "path": "pages/sub",
    "index": ["index.html"]
},
"...": {...}
```
