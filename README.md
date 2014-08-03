
## GUIGNA: the GUI of Guigna is Not by Apple  :)

Guigna* is the prototype of a GUI supporting Homebrew, MacPorts, Fink and pkgsrc
at the same time.


![screenshot](https://raw.github.com/gui-dos/Guigna/master/guigna-screenshot.png)


## Design and ideas

Guigna tries to abstract several package managers by creating generalized classes
(GSystem and GPackage) while keeping a minimalist approach and using screen
scraping. The implementations in Objective-C, Ruby and Swift are being kept in
sync.

Guigna doesn't hide the complexity of compiling open source software: it launches
the shell commands in a Terminal window you can monitor and interrupt. When
administration privilege or another input are required, the answer to the
prompt can be typed directly in the Terminal brought to the foreground thanks
to the Scripting Bridge. 

When multiple package managers are detected, their sandboxes are hidden by appending
`_off` to their prefix before the compilation phase. An on-line mode, however,
allows to get the details about the packages by scraping directly their original
repositories.


## Feedback

Guigna is at a very early stage of development but it is quite stable
for a try (some preliminary builds are available from
[Dropbox](https://www.dropbox.com/sh/ld19r8vp9avr32p/eV6au9iQK3)).

The project is tested only for the latest versions of Xcode, OS X
Mavericks and RubyMotion. It doesn't use the more advanced idioms
and tools available in such environments but I think it is progressing
quite well since it was started as a single script for personal use
while I was reading a couple of books on MacRuby and testing the
Nokogiri gem...

Some advice and warnings:

- Add the system prefixes (`/opt/local`, `/usr/local`, `/sw`) and their
  hidden versions (with a `_off` suffix) to the Private section of the
  Spotlight preference panel, since they are renamed continuously.
  No other modifications are made to the system: simply delete
  `~/Library/Application Support/Guigna` and execute 
  `defaults delete name.soranzio.guido.Guigna` for a fresh restart.
- In systems other than MacPorts and Homebrew many commands don't
  work since they are still sketched mock-ups.
- `Stop` is not implemented yet. Forcing quitting and restarting Guigna
  should offer to unhide the detected prefixes. Remember that, in comparison
  to other traditional GUIs, Guigna is scripting the Terminal and you can
  always check the tasks which are executing in the shell.

```
    GSource is a collection of GItems
       .                         .
      /_\                       /_\
       |                         |             status: available
       |                         |                     uptodate
                                                       outdated
    GSystem                  GPackages                 inactive


    The following GSystem methods execute the corresponding command,
    update the 'items' array and return a copy:

    - list
    - installed
    - outdated
    - inactive

    The following methods build and return the corresponding commands
    as strings:

    -   install_cmd(pkg)
    - uninstall_cmd(pkg)
    -   upgrade_cmd(pkg)
    
    The following methods execute specific commands and return the output:
   
    -     home(pkg)   URL of the original website
    -      log(pkg)   URL of the page listing the versions/commits
    -     info(pkg)   output of the 'info' command
    -     deps(pkg)   list of the dependencies/requirements
    -      cat(pkg)   portfile, formula, spec or makefile
    - contents(pkg)   list of installed files


    Other GSystem methods and properties:

    - index     dictionary of the system's items, having
                'name-system' as keys: it is used for a fast
                access when determining new and updated items

    - [name]    accessor to the indexed package carrying that name

    - prefix    /opt/local, /usr/local, /sw, /usr/pkg, ...

    - cmd       prefix + /bin/port | bin/brew | /bin/fink | ...

    - agent     passed by appDelegate/app_delegate and implementing
                the methods:
                - nodesForURL:XPath: (nodes_for_url(url, xpath) in Ruby)
                - outputForCommand:
                - appDelegate / app_delegate (it gives access to
                  GuignaAppDelegate)

    - outputFor shortcut for calling agent's outputForCommand: method,
                passing a format and a va_list of args
                

    GPackage properties:

    - system     weak reference to its GSystem (GSource)
      (source)

    - installed  installed version (string or nil)

    - mark       enum: install, uninstall, upgrade, fetch, ...

    - options    available variants/options/flags joined by space

    - marked_    variants/options/flags marked by the user for committing
      options

    - *_cmd      shortcuts to self.system.*_cmd, passing itself as argument
      
    Inactive packages are not indexed and are inserted also in
    app_delegate's all_packages / allPackages.

```
--

\* The [Kodkod](http://en.wikipedia.org/wiki/Kodkod) (Leopardus guigna), also
called Guiña, is the smallest cat in the Americas.

![icon](http://www.felineconservation.org/uploads/rauh_handicapped_guina.jpg)

