# piwigo-client
A Ruby client for interacting with a [Piwigo](https://piwigo.org) image management system. The
primary focus at the moment is uploading images to a server; that may expand if I find time and
motivation.

### Piwigo API
An [API explorer](https://piwigo.org/demo/tools/ws.htm) can be found on the Piwigo demo site, or at
`/tools/ws.htm` on your local installation.
[Docs are also available](https://piwigo.org/doc/doku.php?id=dev:webapi:start) although they're
pretty sparse.

### Installation
I haven't done the magic to make this installable anywhere; it relies on `require_relative` so
you're going to want to run it out of the source directory.

Based on `ruby-2.7.2`.

Run `bundle install` to pull gems.

Dependencies:
- `httparty`
- `progress_bar`

### Execution
```
Usage: ./upload_images [options] -c category (file | @list)...

        --config FILE                Set location of JSON configuration file (default: .piwigo.conf).
    -h, --help                       Prints this help

Connection options (required):
    -b, --base_uri HOSTNAME          Hostname of Piwigo server
    -u, --username USERNAME          Username
    -p, --password PASSWORD          Password

Image options:
    -c, --category ID                Piwigo category to upload files into (required)
    -r, --recurse                    Recurse into directories (default: off)

Specifying files:
  List one or more files on the command line after the arguments.
  If a filename starts with @, it will be treated as a newline-separated list of files.
  Directories will be skipped unless -r is turned on.
```
In order to run, the script needs:
- The URL of your Piwigo installation;
- A username/password combination to log in with;
- A category to upload files into;
- One or more files to upload.

#### Configuration Files
To avoid putting your login credentials on the command line, I recommend building a `.piwigo.conf`
file (JSON format). You can store any of the command line options in that file, although the 
connection options are most useful:
```json
{
  "username": "piwigo",
  "password": "piwigo",
  "base_uri": "http://piwigo.local"
}
```
Any options in the config file will be overwritten with anything specified on the command line.
You *can* specify `config` in the config file, but it won't do you any good.

The location of the config file defaults to `.piwigo.conf` in the current directory, but can be
changed with `--config <filename>`.

#### Categories
The target category can either be specified by ID (`-c 150`) or by name (`-c unsorted`). If a
non-integer is detected, the client will pull the list of categories from the server and attempt
to do a case-insensitive, *whole-string* match against the input category name.

If more than one match is detected, the script will print out the ID and full name (including 
parent categories) of the categories that matched, so you can easily re-run with a numeric category
ID.

#### Files to Upload
Command-line arguments that are not captured by the option parser will be treated as filenames.
This allows you to take advantage of shell globbing or `xargs`.

Any file argument that begins with `@` will be read as a list of filenames, one per line. This will
not happen recursively, so if your `@filelist` contains files whose names start with `@` they will
be treated literally.

By default, the script will skip over directories that it finds in the file list (again, to make
using shell globbing easier). This does mean that you should pass `directory/*` rather than
`directory` if you want to upload the entire contents of a given directory.

If you want the script to recurse into directories, pass `--recursive`; however, this will cause it
to pull *every* file in *every* child directory it finds, so use it with caution.

