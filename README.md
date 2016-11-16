#-#-# HistoGlobe #-#-#

visualizes the history of the world on a map and a timeline.
HistoGlobe is a Historical Geographic Information System that aims to act as an interactive historical world atlas.


# SETUP
=======

HistoGlobe consists of
- a server-side application using Django (Python), a PostgreSQL database and the PostGIS plugin for spatial data
- a client-side application using HTML, Less (compiles to CSS) and CoffeeScript (compiles to JavaScript)

## client-side installation
- get an awesome text editor: Atom
  https://atom.io/

- install apache, git and node.js
  $ sudo apt-get install apache2 git nodejs npm

- add node.js modules (Less, CoffeeScript, Rosetta and uglify.js)
  $ sudo npm install -g less less-plugin-clean-css uglify-js coffee-script rosetta

- prevent bug of unavailable node.js
  $ sudo ln -s /usr/bin/nodejs /usr/bin/node

- download this repository
  $ cd project_directory
  $ git clone git@github.com:MenschMarcus/HistoGlobe.git

- build the project and run it
  $ cd project_directory
  $ ./make.sh
  $ python manage.py runserver
  $ chromium-browser --incognito http://localhost:8000

## access Django App on localhost
http://localhost:8000
